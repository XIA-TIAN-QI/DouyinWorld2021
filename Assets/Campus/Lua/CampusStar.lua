-- 黄思诚：女主角 + 好感度系统
--
-- 和 NPCTalk.lua 那几个"路过的人"不是一套逻辑 ——
-- 她不巡逻，她等你：发现玩家就主动迎上来，玩家走动就跟着，走太远才回原位。
-- 在这之上叠了一层好感度：在 TALK_RANGE 内陪着她会慢慢加分（每说一句再加一点），
-- 分四档（初识 / 熟络 / 心动 / 满），到档换一套台词；满档触发收尾：靠得更近 + 专属提示。
--
-- 挂在 NPC_08 的 DouyinScript 上（构建脚本 BuildStar 自动挂），子物体结构：
--   Model/ArmL, ArmR, LegL, LegR   四肢枢轴
--   Model                          整体（待机时做重心偏移，别让站姿像根柱子）
--   Label / Label/Bubble/Line_xx   名牌与台词（贴图 quad，见 NPCTalk.lua 顶部注释）
--   Path/Waypoint_01               待机点
--
-- 台词是预渲染图集（T_NpcLines.png），脚本只切显隐。
-- 分档信息写在 quad 名字里：Line_<档>_<序号>（见 NpcLines.txt 的 L2/L3/L4）。
-- 老场景没有档号（Line_09）就全按第 1 档处理，不会崩。
--
-- 不用 NavMesh：她只在校门→广场这段活动，直线走就够；
-- 玩家上楼/进教学楼她跟不进去（同层判定会让她放弃），这是刻意的 —— 她没有寻路能力，
-- 硬追只会贴着墙根原地磨。

local NOTICE     = 14.0   -- 进入这个距离：发现玩家，主动过来
local TALK_RANGE = 2.60   -- 进入这个距离：开始说话 + 开始涨好感。
                          -- **注意它只控制"说不说"，不控制"走不走"** ——
                          -- 走路的下限是 STOP_AT(1.9)。两个用途用同一个数，她就会在 2.6m 站住不走了
local GIVEUP     = 22.0   -- 超出这个距离：放弃，回原位
local STOP_AT    = 1.9    -- 追到离玩家这么近就停（不贴脸）
local FINALE_AT  = 1.35   -- 满好感后她会站得更近一点
local SPEED      = 2.10   -- 比普通 NPC 快一点，否则跟不上走路的玩家
local TURN_RATE  = 8.0
local TALK_GAP   = 6.1    -- 两句之间的间隔。配音上线后改宽：日语语音最长 5.6s，
                          -- 气泡 4.5s 就收会把声音切断（气泡隐藏会停掉身上的音源）
local BUBBLE_TIME= 6.0
local ARRIVE_EPS = 0.35
local LEVEL_EPS  = 1.0    -- 高度差超过这个就算"换了楼层"，不追

-- 好感度：陪她站着 +3/秒；每说出一句额外 +4。
-- 门槛 30 / 80 / 160 → 大约 10s / 27s / 53s 连续相处到档，短会话也跑得完。
local AFFINITY_MAX      = 220
local AFFINITY_PER_SEC  = 3.0
local AFFINITY_PER_LINE = 4.0
local TIER_THRESH       = { 0, 30, 80, 160 }   -- 下标 1..4

-- 活动范围：只在校门 → 广场这一带。她不会冲进教学楼、也不会跑到操场去
local AREA_X = 13.0
local AREA_Z_MIN, AREA_Z_MAX = -24.0, 12.0

local Q = CS.UnityEngine.Quaternion
local V = CS.UnityEngine.Vector3

local root, model
local armL, armR, legL, legR
local label, bubble
local promptQuad          -- 气泡下方的「按 F 继续 ▼」提示条
local home

local tierLines = {}     -- [档] = { quad, ... }
local allQuads = {}      -- 扁平表，换句时统一关
local tierCursor = {}    -- [档] = 下一句下标

local phase = 0
local nextLineAt = 0
local bubbleHideAt = 0
local engaged = false
local talkedOnce = false -- F 键模式：这次靠近是否已经开过口（开过之后只按 F 推进）

local affinity = 0
local tier = 1
local finalePlayed = false
local finalePose = false

-- 前向声明：UpdateTier 在上面就要用（Lua 的 local 按词法作用域，不提前声明
-- 闭包里会解析成全局 nil）
local SaveAffinity
local saveHooked = false

-- 毕业典礼：集齐八枚后 CampusCeremony 会调 OnCeremony()，她会放下一切走向广场。
-- 第 4 档最后一句是典礼专用（"典礼开始了，别站那么远"），不在日常轮播里出现 ——
-- 否则玩家在好感刚满时就听完了，真到典礼反而没话说。
local ceremonyMode = false
local ceremonySaid = false
local ceremonyQuad = nil
local CEREMONY_X, CEREMONY_Z = 0.0, 0.0
local CEREMONY_SPEED = 2.2      -- 从校门口跑到广场有 20m，按常速要 9 秒，会错过烟花

-- ---------------------------------------------------------------- 小工具

local function FindChild(parent, path)
    if parent == nil then return nil end
    return parent:Find(path)
end

local function GetLocalActor()
    local ok, actor = pcall(function()
        return CS.DouyinActorService.GetLocalActor()
    end)
    if ok then return actor end
    return nil
end

local function ActorPos(actor)
    if actor == nil then return nil end
    local go = actor.gameObject
    if go == nil then return nil end
    return go.transform.position
end

local function Dist(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function HideBubble()
    if bubble ~= nil then bubble.gameObject:SetActive(false) end
end

local function Toast(msg)
    local ok = pcall(function()
        CS.DouyinUtility.Toast(msg)
    end)
    if not ok then print("[CampusStar] " .. msg) end
end

-- ---------------------------------------------------------------- 台词分档

-- 台词配音：音源直接挂在 quad 上（构建脚本按 Voice/<quadName>.ogg 有文件才挂）。
-- 气泡隐藏 SetActive(false) 时 Unity 自动停掉它身上的声音 —— "人走了话就停"符合直觉。
-- 全程 pcall：真机 XLua 是否暴露 AudioSource 未验证，缺什么都不许拖垮气泡。
local function PlayVoice(q)
    local ok, err = pcall(function()
        local src = q.gameObject:GetComponent(typeof(CS.UnityEngine.AudioSource))
        if src ~= nil and src.clip ~= nil then
            src:Play()
            print("[CampusStar] 配音 " .. q.name)
        end
    end)
    if not ok then print("[CampusStar] 配音跳过: " .. tostring(err)) end
end

-- 只开一块 quad：图集方案下换台词 = 换显隐，没有文本可改
-- hold=true 时字幕不自动消失（F 键模式：停留到按 F 或玩家走开）
local function ShowQuad(q, hold)
    for i = 1, #allQuads do
        allQuads[i].gameObject:SetActive(allQuads[i] == q)
    end
    if bubble ~= nil then bubble.gameObject:SetActive(true) end
    bubbleHideAt = CS.UnityEngine.Time.time + (hold and 0 or BUBBLE_TIME)
    PlayVoice(q)
end

-- 取某一档的台词；这一档是空的就往前退一档（老场景只有 Line_01 时也能跑）
local function TierList(t)
    local list = tierLines[t]
    while (list == nil or #list == 0) and t > 1 do
        t = t - 1
        list = tierLines[t]
    end
    return list or {}
end

local function SayFromTier(t)
    local list = TierList(t)
    if #list == 0 then return end
    -- 第 4 档最后一句是典礼专用，日常轮播只在前 n-1 句里转
    local maxIdx = #list
    if t >= 4 and ceremonyQuad ~= nil and maxIdx > 1 then
        maxIdx = maxIdx - 1
    end
    local idx = tierCursor[t] or 1
    if idx < 1 or idx > maxIdx then idx = 1 end
    ShowQuad(list[idx])
    tierCursor[t] = idx % maxIdx + 1
end

local function TierFor(a)
    local t = 1
    for i = 2, #TIER_THRESH do
        if a >= TIER_THRESH[i] then t = i end
    end
    return t
end

local function PlayFinale()
    finalePose = true
    if finalePlayed then return end
    finalePlayed = true
    -- 收尾那句多停一会儿，让玩家看清楚
    if bubble ~= nil then
        bubbleHideAt = CS.UnityEngine.Time.time + BUBBLE_TIME + 1.5
    end
    Toast("黄思诚 的好感已满 · 她好像有话对你说")
end

-- 只升不降：离开再回来不会掉档（短会话里惩罚感太重）
local function UpdateTier()
    local nt = TierFor(affinity)
    if nt <= tier then return end
    tier = nt
    tierCursor[tier] = 1
    if tier >= 4 then
        PlayFinale()
    else
        Toast(string.format("黄思诚 好感提升 · 第 %d 档", tier))
    end
    SaveAffinity(true)       -- 升档是关键节点，立刻落盘，别等定期写
end

-- ---------------------------------------------------------------- 存档
-- 存档层在 CampusSave.lua。好感度是浮点、每帧都在涨，所以这里只做两件事：
--   1. 读档到了就把 affinity 抬到存档值，并按档位重算（**不弹 Toast、不重播收尾**，
--      重进世界不该再提示一遍"好感已满"）
--   2. 每帧把当前值同步进存档层的内存缓存，真正落盘由 CampusSave 自己按 4 秒节流，
--      升档时再强制写一次

local function Restore()
    local save = _G["CampusSave"]
    if save == nil then return end

    local a = tonumber(save.Get("affinity", 0)) or 0
    if a <= affinity then return end

    affinity = math.min(AFFINITY_MAX, a)
    local nt = TierFor(affinity)
    if nt > tier then
        tier = nt
        for t = 1, nt do tierCursor[t] = 1 end
        if nt >= 4 then
            -- 已经满档：直接进收尾姿态，但不再弹提示
            finalePlayed = true
            finalePose = true
        end
    end
    print(string.format("[CampusStar] 存档恢复：好感 %d，第 %d 档", math.floor(affinity), tier))
end

function SaveAffinity(force)
    local save = _G["CampusSave"]
    if save == nil then return end
    -- 不自己缓存"上次写到多少"：被节流跳过时会永久漏写。交给 CampusSave 按内容比对。
    save.Set("affinity", math.floor(affinity))
    if force then save.Flush(true) end
end

local function TryHookSave()
    if saveHooked then return end
    local save = _G["CampusSave"]
    if save == nil then return end
    saveHooked = true
    save.OnReady(Restore)
end

-- 对外只读状态。结局系统靠 IsMax() 判断"她会不会陪你参加毕业典礼"——
-- 第 4 档台词「毕业典礼那天，我陪你去」就是挂在这个条件上的，不能是句空话。
local StarApi = {}
function StarApi.IsMax() return tier >= 4 end
function StarApi.Tier() return tier end
function StarApi.Affinity() return math.floor(affinity) end

-- 由 CampusCeremony 在毕业典礼开始时调用：她放下手头的事，走向广场。
-- 这一步让第 4 档那句"毕业典礼那天，我陪你去"真的兑现，而不只是句台词。
function StarApi.OnCeremony()
    ceremonyMode = true
    ceremonySaid = false
    print("[CampusStar] 典礼开始，她动身去广场")
end

-- ---------------------------------------------------------------- 键盘输入
-- F 键推进对话。SDK 的 Lua 没有输入先例，全走 pcall：摸不到 Input 就自动
-- 退回原来的"定时轮播"，提示条也不显示（显示就是撒谎）。

local inputOK = nil        -- nil=还没探测，true/false=探测结果

local function InputReady()
    if inputOK ~= nil then return inputOK end
    local ok, has = pcall(function()
        return CS.UnityEngine.Input ~= nil and CS.UnityEngine.Input.GetKeyDown ~= nil
    end)
    inputOK = (ok and has == true)
    if inputOK then
        print("[CampusStar] 键盘输入可用：按 F 推进对话")
    else
        print("[CampusStar] 键盘输入不可用，保持自动轮播")
    end
    return inputOK
end

local function FPressed()
    if not InputReady() then return false end
    local ok, hit = pcall(function()
        return CS.UnityEngine.Input.GetKeyDown(CS.UnityEngine.KeyCode.F)
    end)
    if not ok then
        inputOK = false
        print("[CampusStar] 读取键盘失败，退回自动轮播")
        return false
    end
    return hit == true
end

local function ShowPrompt(v)
    if promptQuad ~= nil and promptQuad.gameObject.active ~= v then
        promptQuad.gameObject:SetActive(v)
    end
end

-- 只说不动：是否走到位由 Tick 里的 stopDist 判断，两个距离不能混用
-- F 键模式下一句只在按键时说；0.35s 防抖防止按住 F 刷屏
local function AdvanceLine()
    SayFromTier(tier)
    nextLineAt = CS.UnityEngine.Time.time + (InputReady() and 0.35 or TALK_GAP)
    affinity = math.min(AFFINITY_MAX, affinity + AFFINITY_PER_LINE)
    UpdateTier()
end

local function TrySay()
    local now = CS.UnityEngine.Time.time
    if now < nextLineAt then return end
    AdvanceLine()
end

-- ---------------------------------------------------------------- 姿态

-- 待机/说话：右手叉腰，重心缓慢压到一侧。这个"站着也要有型"的姿势是她和路人最大的区别
local function PoseIdle(now)
    if armR ~= nil then armR.localRotation = Q.Euler(6, 0, -34) end
    if armL ~= nil then armL.localRotation = Q.Euler(-4, 0, 7) end
    if legL ~= nil then legL.localRotation = Q.identity end
    if legR ~= nil then legR.localRotation = Q.identity end
    if model ~= nil then
        model.localPosition = V(0, math.sin(now * 1.2) * 0.008, 0)
        model.localRotation = Q.Euler(0, 0, math.sin(now * 0.75) * 1.1)
    end
end

-- 满好感：手放下来，不再叉腰（叉腰是"生人勿近"的架子），整个人松下来
local function PoseFinale(now)
    if armR ~= nil then armR.localRotation = Q.Euler(9, 0, -6) end
    if armL ~= nil then armL.localRotation = Q.Euler(-9, 0, 6) end
    if legL ~= nil then legL.localRotation = Q.identity end
    if legR ~= nil then legR.localRotation = Q.identity end
    if model ~= nil then
        model.localPosition = V(0, math.sin(now * 1.1) * 0.006, 0)
        model.localRotation = Q.Euler(0, 0, math.sin(now * 0.9) * 0.8)
    end
end

-- 走路：手臂收回来正常摆（抱腰的手不摆会像抽筋），步子比路人利落
local function PoseWalk()
    local swing = math.sin(phase) * 26
    if legL ~= nil then legL.localRotation = Q.Euler(swing, 0, 0) end
    if legR ~= nil then legR.localRotation = Q.Euler(-swing, 0, 0) end
    if armL ~= nil then armL.localRotation = Q.Euler(-swing * 0.95, 0, 4) end
    if armR ~= nil then armR.localRotation = Q.Euler(swing * 0.95, 0, -4) end
    if model ~= nil then
        model.localPosition = V(0, math.abs(math.sin(phase)) * 0.030, 0)
        model.localRotation = Q.identity
    end
end

local function FaceTo(dx, dz, dt)
    if math.abs(dx) + math.abs(dz) < 0.0001 then return end
    local want = Q.LookRotation(V(dx, 0, dz))
    root.rotation = Q.Slerp(root.rotation, want, math.min(1, dt * TURN_RATE))
end

-- ---------------------------------------------------------------- 移动

-- 目标点先夹到活动范围内：玩家跑到操场或楼上时，她会走到范围边缘停下等，
-- 而不是一路贴着墙根往前蹭
local function ClampTarget(p)
    local x = p.x
    local z = p.z
    if x < -AREA_X then x = -AREA_X elseif x > AREA_X then x = AREA_X end
    if z < AREA_Z_MIN then z = AREA_Z_MIN elseif z > AREA_Z_MAX then z = AREA_Z_MAX end
    return V(x, root.position.y, z)
end

local function MoveTo(target, dt, stopAt, speedScale)
    local pos = root.position
    local dx, dz = target.x - pos.x, target.z - pos.z
    local d = math.sqrt(dx * dx + dz * dz)
    if d < stopAt then
        PoseIdle(CS.UnityEngine.Time.time)
        return true
    end

    local step = SPEED * (speedScale or 1) * dt
    if step > d - stopAt then step = math.max(0, d - stopAt) end
    if step <= 0 then
        PoseIdle(CS.UnityEngine.Time.time)
        return true
    end

    local nx, nz = dx / d, dz / d
    root.position = V(pos.x + nx * step, pos.y, pos.z + nz * step)
    FaceTo(nx, nz, dt)

    phase = phase + step * 3.6
    PoseWalk()
    return false
end

-- ---------------------------------------------------------------- 状态

local function ChaseTo(playerPos, dt, stopAt)
    local target = ClampTarget(playerPos)
    local moved = MoveTo(target, dt, stopAt)
    -- 走到边上了（玩家在范围外）：站着等，但脸朝玩家
    if moved then
        FaceTo(playerPos.x - root.position.x, playerPos.z - root.position.z, dt * 1.2)
    end
end

local function GoHome(dt)
    if home == nil then
        PoseIdle(CS.UnityEngine.Time.time)
        return
    end
    local target = V(home.x, root.position.y, home.z)
    if MoveTo(target, dt, ARRIVE_EPS) then
        -- 到家：转回朝校门（-z），继续摆姿势等人
        FaceTo(0, -1, dt)
    end
end

-- ---------------------------------------------------------------- 生命周期

function Awake()
    root = self.transform
    model = FindChild(root, "Model")
    armL = FindChild(model, "ArmL")
    armR = FindChild(model, "ArmR")
    legL = FindChild(model, "LegL")
    legR = FindChild(model, "LegR")

    label = FindChild(root, "Label")
    bubble = FindChild(root, "Label/Bubble")
    promptQuad = bubble ~= nil and FindChild(bubble, "Prompt_F") or nil

    -- 台词 quad：按名字里的档号分组，组内按名字排序（Line_2_09 < Line_2_10）
    -- ⚠️ 只收 Line_ 命名的子物体 —— Prompt_F 这类提示条混进来会被 ShowQuad 当
    --    台词一起切显隐，和 ShowPrompt 打架
    tierLines = {}
    allQuads = {}
    tierCursor = {}
    if bubble ~= nil then
        for i = 0, bubble.childCount - 1 do
            local c = bubble:GetChild(i)
            local tierNum = string.match(c.name, "^Line_(%d+)_%d+$")   -- 新：Line_2_09
            local legacy  = string.match(c.name, "^Line_%d+$")          -- 旧：Line_09（老场景没重建时）
            if tierNum ~= nil or legacy ~= nil then
                local t = tonumber(tierNum) or 1
                if tierLines[t] == nil then tierLines[t] = {} end
                table.insert(tierLines[t], c)
                allQuads[#allQuads + 1] = c
            end
        end
        for _, list in pairs(tierLines) do
            table.sort(list, function(a, b) return a.name < b.name end)
        end
    end

    -- 第 4 档的最后一句留给典礼（见 SayFromTier 的排除逻辑）。
    -- 只有一句的时候不排除，否则日常就没话说了。
    ceremonyQuad = nil
    local l4 = tierLines[4]
    if l4 ~= nil and #l4 >= 2 then
        ceremonyQuad = l4[#l4]
    end

    local pathRoot = FindChild(root, "Path")
    if pathRoot ~= nil and pathRoot.childCount > 0 then
        home = pathRoot:GetChild(0).position
    end

    phase = 0
    nextLineAt = 0
    bubbleHideAt = 0
    engaged = false
    affinity = 0
    tier = 1
    finalePlayed = false
    finalePose = false
    saveHooked = false
    ceremonyMode = false
    ceremonySaid = false
    talkedOnce = false
    HideBubble()
    ShowPrompt(false)
    _G["CampusStar"] = StarApi
    TryHookSave()          -- 存档若已就绪会立刻把好感度抬回来

    print(string.format("[CampusStar] %s ready, lines=%d, home=%s",
        tostring(root.name), #allQuads, home ~= nil and tostring(home) or "nil"))
end

-- ---------------------------------------------------------------- 帧驱动
-- 和 NPCTalk.lua 一样：SDK 官方示例只实现 LateUpdate()，所以三个入口全挂、按帧号去重。
-- 日志 via= 会告诉你实际生效的是哪个。

local lastFrame = -1
local tickCount = 0
local tickVia = nil
local diagCount = 0

local function Diag(tag, playerPos, d, dt)
    if diagCount >= 14 then return end
    diagCount = diagCount + 1
    local fc = CS.UnityEngine.Time.frameCount
    if fc == nil then fc = -1 end
    print(string.format("[CampusStar] %s %s tick=%d via=%s frame=%d dt=%.3f player=%s d=%s aff=%.0f tier=%d",
        tostring(root ~= nil and root.name or "?"), tag, tickCount, tostring(tickVia),
        fc, dt,
        playerPos ~= nil and string.format("(%.2f,%.2f,%.2f)", playerPos.x, playerPos.y, playerPos.z) or "nil",
        d ~= nil and string.format("%.2f", d) or "nil",
        affinity, tier))
end

local function Tick(dt, source)
    local f = CS.UnityEngine.Time.frameCount
    if f == nil then f = CS.UnityEngine.Time.time end
    if f == lastFrame then return end
    lastFrame = f
    tickCount = tickCount + 1
    if tickVia == nil then tickVia = source end

    if dt <= 0 then return end
    if dt > 0.2 then dt = 0.2 end

    TryHookSave()          -- CampusSave 可能比本脚本晚 Awake，这里补挂

    local now = CS.UnityEngine.Time.time
    if bubbleHideAt > 0 and now >= bubbleHideAt then
        HideBubble()
        bubbleHideAt = 0
    end

    local playerPos = ActorPos(GetLocalActor())
    local d = nil
    if playerPos ~= nil then
        d = Dist(root.position, playerPos)
    end

    -- 名牌正对玩家。quad 正向面（文字不镜像的那面）朝 +Z，所以让 +Z 指向玩家：
    -- LookRotation(playerPos - label.position)。用玩家位置而非 Camera.main（真机拿不到）。
    if label ~= nil and playerPos ~= nil then
        local toPlayer = playerPos - label.position
        if toPlayer.sqrMagnitude > 0.0001 then
            label.rotation = Q.LookRotation(toPlayer)
        end
    end

    if tickCount <= 2 or (tickCount % 300 == 0) then
        Diag(tickCount <= 2 and "启动" or "周期", playerPos, d, dt)
    end

    -- 毕业典礼：走向广场。不看玩家在哪 —— 典礼时玩家可能正在别处逛，
    -- 她答应的是"来参加典礼"，不是"跟着你"。
    if ceremonyMode then
        ShowPrompt(false)     -- 典礼时提示条没有意义，收掉
        local target = V(CEREMONY_X, root.position.y, CEREMONY_Z)
        if MoveTo(target, dt, 1.0, CEREMONY_SPEED) then
            FaceTo(0, 1, dt)
            PoseFinale(now)
            if not ceremonySaid then
                ceremonySaid = true
                if ceremonyQuad ~= nil then
                    ShowQuad(ceremonyQuad)
                    print("[CampusStar] 典礼台词：" .. ceremonyQuad.name)
                end
            end
        end
        return
    end

    if playerPos == nil then
        GoHome(dt)
        return
    end

    local sameLevel = math.abs(playerPos.y - root.position.y) <= LEVEL_EPS

    -- 发现/放弃都要过门槛，避免她在 14~22m 之间反复启停
    if sameLevel and d <= NOTICE then
        engaged = true
    end
    if (not sameLevel) or d > GIVEUP then
        engaged = false
    end

    if not engaged then
        ShowPrompt(false)
        if talkedOnce then
            talkedOnce = false
            HideBubble()          -- F 模式的字幕没有定时器，彻底走远要在这里收
            bubbleHideAt = 0
        end
        GoHome(dt)
        return
    end

    -- 走路：一直走到 stopDist 才停 —— 她会真的走到你身边，不是隔着三米喊话
    local stopDist = finalePose and FINALE_AT or STOP_AT
    if d <= stopDist then
        FaceTo(playerPos.x - root.position.x, playerPos.z - root.position.z, dt * 1.4)
        if finalePose then PoseFinale(now) else PoseIdle(CS.UnityEngine.Time.time) end
    else
        ChaseTo(playerPos, dt, stopDist)
    end

    -- 说话 + 涨好感：TALK_RANGE 内持续累积，说的每一句再加一点
    if d <= TALK_RANGE then
        affinity = math.min(AFFINITY_MAX, affinity + AFFINITY_PER_SEC * dt)
        UpdateTier()

        -- 键盘可用：F 键推进对话；字幕停着不走（停留到按 F 或离开）
        if InputReady() then
            ShowPrompt(true)
            if not talkedOnce then
                talkedOnce = true
                AdvanceLine()
                bubbleHideAt = 0
            elseif FPressed() and CS.UnityEngine.Time.time >= nextLineAt then
                AdvanceLine()
                bubbleHideAt = 0
            end
        else
            -- 回退：读不到键盘就保持原来的定时轮播
            ShowPrompt(false)
            TrySay()
        end
        SaveAffinity(false)   -- 只同步到内存，落盘交给 CampusSave 的定期节流
    else
        -- 走出对话距离：收字幕和提示，重开一次"第一句"
        if talkedOnce then
            talkedOnce = false
            HideBubble()
            bubbleHideAt = 0
        end
        ShowPrompt(false)
    end
end

-- ---------------------------------------------------------------- 入口

function Update()     Tick(CS.UnityEngine.Time.deltaTime, "Update")     end
function LateUpdate() Tick(CS.UnityEngine.Time.deltaTime, "LateUpdate") end
function OnUpdate()   Tick(CS.UnityEngine.Time.deltaTime, "OnUpdate")   end

function OnDestroy()
    if _G["CampusStar"] == StarApi then
        _G["CampusStar"] = nil
    end
end
