-- 校园存档：把校徽进度、任务状态、好感度持久化到 SDK 的 DouyinDataStore
--
-- 挂在场景里一个独立的空宿主上（构建脚本 BuildSaveHost 自动生成），
-- 通过 _G["CampusSave"] 给 CampusCollect.lua / CampusStar.lua 用。
--
-- 数据来源是 SDK 自带的 DouyinDataStore 示例（Assets/DouyinVCreateSDK/World/Examples/
-- DouyinDataStore），那份 prefab 里有 NetGUID 网络组件，必须由 SDK 实例化、不能自己 new，
-- 所以这里只做业务层，真正的 DATASTORE() 异步调用交给官方的 DouyinDataStoreManager。
--
-- ⚠️ 四个必须守住的点，改这个脚本前先看：
--   1. **加载失败时绝对不许写盘**。ready=false 时 WriteNow 直接返回 —— 否则拿默认值
--      （全 0）去覆盖服务端已有存档，玩家进度就没了。
--   2. **scope 用 playerOpenID**，不能用固定字符串。这是多人世界，用固定 scope 会让
--      所有玩家共用一份存档。官方 DouyinPlayerDataStore 也就是把 openID 当 scope 传。
--   3. **写入限速**：平台配额约 900 次/分钟。好感度每帧都在涨，绝不能每帧写。
--      这里走"定期对比"：每 WRITE_GAP 秒序列化一次，内容和服务端一致就跳过。
--   4. **不依赖 dkjson**。官方 manager 用 dkjson.encode 处理 table，但工程里没有
--      dkjson 文件（是引擎注入的），为了少一个不确定项，这里自己写扁平串行化。
--
-- 存储格式（单键，避免多个脚本 read-modify-write 互相覆盖）：
--   v1;e=10110010;q=1;a=42
--   e = 8 枚校徽（1 已入柜 / 0 未拾取），q = 是否接过任务，a = 好感度（整数）

local VERSION       = "v1"
local STORE_NAME    = "campus"    -- store 名
local DATA_KEY      = "save"      -- 只用一个键装全部状态
local EMBLEM_BITS   = 8           -- 必须和 CampusCollect.lua 的 TOTAL 一致
local WRITE_GAP     = 4.0         -- 两次写盘的最小间隔（秒）
local LOAD_RETRIES  = 3           -- 读档最多试几次
local RETRY_GAP     = 20.0        -- 读档失败后隔多久再试（秒）
local LOAD_TIMEOUT  = 8.0         -- 单个读档请求多久没回来算超时（见 TryLoad 注释）

local manager = nil               -- DouyinDataStoreManager（SDK prefab 上的脚本）
local openID = nil                -- 当前玩家的 openID，同时充当 store 的 scope
local ready = false               -- 存档是否已成功读到（未 ready 时禁止写）
local loading = false
local loadingAt = 0               -- 本次读档发起的时间，用来判超时
local failedTries = 0
local nextRetryAt = 0

local lastWriteAt = -9999
local lastSaved = nil             -- 上一次成功写盘的内容，用来跳过无变化的写

local data = { emblems = "00000000", quest = 0, affinity = 0 }
local waiters = {}                -- 数据到达后要通知的回调

-- ---------------------------------------------------------------- 小工具

local function Now()
    local ok, t = pcall(function() return CS.UnityEngine.Time.time end)
    if ok and t ~= nil then return t end
    return os.clock()
end

local function PadEmblems(s)
    s = string.gsub(tostring(s or ""), "[^01]", "")
    if #s < EMBLEM_BITS then
        s = s .. string.rep("0", EMBLEM_BITS - #s)
    elseif #s > EMBLEM_BITS then
        s = string.sub(s, 1, EMBLEM_BITS)
    end
    return s
end

local function Serialize()
    return string.format("%s;e=%s;q=%d;a=%d",
        VERSION,
        PadEmblems(data.emblems),
        math.floor(tonumber(data.quest) or 0),
        math.floor(tonumber(data.affinity) or 0))
end

-- 返回 true 表示确实从存档里解出了东西（新玩家拿到空表时返回 false）
local function Deserialize(raw)
    if type(raw) ~= "string" or raw == "" then return false end
    local hit = false
    for k, v in string.gmatch(raw, "([%w_]+)=([^;]*)") do
        if k == "e" then
            data.emblems = PadEmblems(v)
            hit = true
        elseif k == "q" then
            data.quest = tonumber(v) or 0
            hit = true
        elseif k == "a" then
            data.affinity = tonumber(v) or 0
            hit = true
        end
    end
    return hit
end

-- ---------------------------------------------------------------- 对外 API

local Api = {}

function Api.Available()
    return manager ~= nil and openID ~= nil
end

function Api.Ready()
    return ready
end

function Api.Get(key, default)
    if not ready then return default end
    local v = data[key]
    if v == nil then return default end
    return v
end

function Api.Set(key, value)
    if key == nil or value == nil then return end
    data[key] = value
end

-- 数据到达后执行；已经到达就立刻执行。CampusCollect / CampusStar 靠这个恢复状态
function Api.OnReady(fn)
    if type(fn) ~= "function" then return end
    if ready then
        local ok, err = pcall(fn)
        if not ok then print("[CampusSave] 就绪回调出错 " .. tostring(err)) end
        return
    end
    waiters[#waiters + 1] = fn
end

-- ---------------------------------------------------------------- 读写

local function WriteNow(force)
    -- 第 1 条铁律：没读到过存档就不许写
    if not ready or manager == nil or openID == nil then return false end

    local payload = Serialize()
    if payload == lastSaved then return false end

    local now = Now()
    if not force and now - lastWriteAt < WRITE_GAP then return false end
    lastWriteAt = now

    local ok, err = pcall(function()
        manager.SetData(STORE_NAME, openID, DATA_KEY, payload, function(code, message, value)
            if code then
                lastSaved = payload
                print("[CampusSave] 写盘 " .. payload)
            else
                -- 失败不算数：lastSaved 不更新，下一个周期会自动重试
                print("[CampusSave] 写盘失败 " .. tostring(message))
            end
        end)
    end)
    if not ok then
        print("[CampusSave] SetData 异常 " .. tostring(err))
        return false
    end
    return true
end

function Api.Flush(force)
    return WriteNow(force == true)
end

local function FireReady()
    local list = waiters
    waiters = {}
    for i = 1, #list do
        local ok, err = pcall(list[i])
        if not ok then print("[CampusSave] 就绪回调出错 " .. tostring(err)) end
    end
end

local function FinishLoad(raw, isNew)
    ready = true
    data.emblems = PadEmblems(data.emblems)
    -- 初次读到 / 新建时不视为"待写"，避免刚进世界就白写一次。
    -- ⚠️ 这里不能写成 `lastSaved = isNew and nil or Serialize()` —— Lua 的 and/or
    -- 三元式在中间值为 nil 时会落到 or 分支，结果永远是 Serialize()，新玩家就
    -- 建不出初始记录了（这个坑被 lua_save_test 的 [1] 抓到）。
    if isNew then
        lastSaved = nil
    else
        lastSaved = Serialize()
    end
    print(string.format("[CampusSave] 已就绪 %s (%s)", Serialize(), isNew and "新玩家" or "读到存档"))
    FireReady()
end

local function TryLoad()
    if ready or loading then return end
    if manager == nil or openID == nil then return end

    loading = true
    loadingAt = Now()
    -- ⚠️ 回调可能永远不回来：manager 内部是 DATASTORE(function() ... end)，
    -- 如果那个队列没被引擎驱动（或服务端无响应），loading 会一直挂着，
    -- TryLoad 再也进不来，结果就是"整局都不 ready、也不写盘"——
    -- 看起来像存档接好了，其实一个字都没存。Tick 里有超时兜底。
    local ok, err = pcall(function()
        manager.GetData(STORE_NAME, openID, DATA_KEY, function(code, message, value)
            loading = false
            if code then
                local hit = Deserialize(value)
                FinishLoad(value, not hit)
            else
                failedTries = failedTries + 1
                nextRetryAt = Now() + RETRY_GAP
                print(string.format("[CampusSave] 读档失败(%d/%d) %s",
                    failedTries, LOAD_RETRIES, tostring(message)))
                if failedTries >= LOAD_RETRIES then
                    print("[CampusSave] 放弃读档：本次会话不写盘，避免覆盖服务端存档")
                end
            end
        end)
    end)
    if not ok then
        loading = false
        failedTries = failedTries + 1
        nextRetryAt = Now() + RETRY_GAP
        print("[CampusSave] GetData 异常 " .. tostring(err))
    end
end

-- ---------------------------------------------------------------- 玩家

local function GetLocalPlayer()
    local p = nil
    local ok = pcall(function() p = DouyinPlayerService.GetLocalPlayer() end)
    if ok and p ~= nil then return p end
    ok = pcall(function() p = CS.DouyinPlayerService.GetLocalPlayer() end)
    if ok and p ~= nil then return p end
    return nil
end

local function ResolveOpenID(player)
    if player == nil then return nil end
    local id = nil
    pcall(function() id = player.playerOpenID end)
    if id == nil or tostring(id) == "" then
        pcall(function() id = player:GetOpenID() end)
    end
    if id == nil or tostring(id) == "" then return nil end
    return tostring(id)
end

local function TryResolvePlayer()
    if openID ~= nil then return true end
    if manager == nil then manager = _G["DouyinDataStoreManager"] end
    local p = GetLocalPlayer()
    if p == nil then return false end
    local id = ResolveOpenID(p)
    if id == nil then return false end
    openID = id
    print("[CampusSave] 玩家 " .. openID)
    return true
end

-- ---------------------------------------------------------------- 生命周期

function Awake()
    manager = _G["DouyinDataStoreManager"]
    openID = nil
    ready = false
    loading = false
    failedTries = 0
    nextRetryAt = 0
    lastWriteAt = -9999
    lastSaved = nil
    data = { emblems = "00000000", quest = 0, affinity = 0 }
    waiters = {}
    _G["CampusSave"] = Api
    print("[CampusSave] init, manager=" .. tostring(manager ~= nil))
end

function OnDestroy()
    if _G["CampusSave"] == Api then
        _G["CampusSave"] = nil
    end
end

-- 玩家进世界：比每帧轮询更早拿到 openID
function OnPlayerJoin(player)
    if openID == nil then
        local id = ResolveOpenID(player)
        if id ~= nil then
            openID = id
            print("[CampusSave] OnPlayerJoin " .. openID)
        end
    end
    TryLoad()
end

-- ---------------------------------------------------------------- 帧驱动
-- 和 NPCTalk / CampusStar 一样：SDK 不一定派发 Update，三个入口全挂、按帧号去重。
-- 这里只做两件事：等 manager/玩家就绪 → 读档；就绪后按间隔比对写盘。

local lastFrame = -1

local function Tick()
    local f = CS.UnityEngine.Time.frameCount
    if f == nil then f = Now() end
    if f == lastFrame then return end
    lastFrame = f

    if manager == nil then manager = _G["DouyinDataStoreManager"] end

    if openID == nil then
        if not TryResolvePlayer() then return end
    end
    if manager == nil then return end

    if not ready then
        -- 读档超时：回调没回来就当作失败，否则会永久卡在 loading=true
        if loading and Now() - loadingAt > LOAD_TIMEOUT then
            loading = false
            failedTries = failedTries + 1
            nextRetryAt = Now() + RETRY_GAP
            print(string.format("[CampusSave] 读档超时(%d/%d)，%0.f 秒无响应",
                failedTries, LOAD_RETRIES, LOAD_TIMEOUT))
        end
        if not loading and failedTries < LOAD_RETRIES and Now() >= nextRetryAt then
            TryLoad()
        end
        return
    end

    if Now() - lastWriteAt >= WRITE_GAP then
        WriteNow(false)
    end
end

function Update()     Tick() end
function LateUpdate() Tick() end
function OnUpdate()   Tick() end
