-- 毕业典礼：集齐八枚校徽之后的那场演出
--
-- 为什么单独一个脚本：这是一段有时序的"演出"（等灯光秀 → 放烟花 → 通知女主角 →
-- 记标记），塞进 CampusCollect 会让收集脚本变成什么都干的怪物。收集脚本只管
-- "收了几枚"，演出由这里负责。
--
-- 触发方式：**轮询** CampusQuest:IsComplete()，不去改 CampusCollect。
--   CampusCollect 和本脚本的 Awake 顺序不保证，"集齐时回调"要么丢事件要么要额外
--   处理"回调注册晚于事件"的情况。轮询简单且天然抗时序。
--
-- 三件事：
--   1. 等灯光秀演完（光柱由 CampusCollect 逐个点亮，8 × 0.28 ≈ 2.24s）
--   2. 放 4 发烟花（1 个升空弹 + 12 个爆散火星循环复用）
--   3. 演完把 ceremony 标记写进存档，重进世界不再重播
--
-- ⚠️ 找节点必须用 Transform:Find，不能用 GameObject.Find：
--    烟花节点初始是 inactive 的，而 GameObject.Find **不返回** inactive 物体。
--    （Plaza_Reward 用的是另一套解法：根节点常驻 active，只隐藏子物体。）
--
-- 不占新的材质额度：火星和升空弹都用 M_Glow（VFX_Add01 加法），
-- 网格是低面球，靠缩放和位置变化做出"散开 + 下坠 + 缩小"的感觉。

local FIREWORK_DELAY = 2.6    -- 等灯光秀演完再放第一发
local SHOT_GAP       = 2.6    -- 两发之间（要 > SPARK_LIFE，否则复用节点会打架）
local SPARK_LIFE     = 2.2
local ROCKET_LIFE    = 0.5
local SPARK_COUNT    = 12
local MAX_SHOTS      = 4
local GRAVITY        = -5.2   -- 火星下坠，纯视觉，不用真实重力
local SAVE_WAIT      = 6.0    -- 存档层迟迟没就绪时，等这么久就直接演

local group       -- 烟花父节点（active，子物体才是隐藏的那个）
local rocket      -- 升空弹
local sparks = {} -- 12 个爆散火星

local playing = false
local nextShotAt = 0
local shotsFired = 0
local waitSaveAt = 0
local anims = {}  -- 正在飞的粒子：{tf, p0, v0, t0, life, s0}

local V = CS.UnityEngine.Vector3

local function Now()
    local ok, t = pcall(function() return CS.UnityEngine.Time.time end)
    if ok and t ~= nil then return t end
    return os.clock()
end

local function Toast(msg)
    local ok = pcall(function()
        CS.DouyinUtility.Toast(msg)
    end)
    if not ok then print("[CampusCeremony] " .. msg) end
end

-- ---------------------------------------------------------------- 音频
-- BGM/音效挂在场景的 CampusAudio 节点上（构建脚本 BuildAudio 生成：
-- BGM_Ambient 日常 loop / BGM_Ceremony 典礼主题 / SFX_Firework 烟花一声）。
-- 音频是"运行时未验证"路径 —— 真机播放、XLua 是否暴露 AudioSource 都没法本地验，
-- 所以每个调用都包 pcall：链路上任何一环缺失都只跳过，绝不拖垮演出。

local function AudioSrc(name)
    local ok, src = pcall(function()
        local root = CS.UnityEngine.GameObject.Find("CampusAudio")
        if root == nil then return nil end
        local t = root.transform:Find(name)
        if t == nil then return nil end
        return t.gameObject:GetComponent(typeof(CS.UnityEngine.AudioSource))
    end)
    if ok then return src end
    return nil
end

-- 开演音乐：典礼主题起 + 日常 BGM 压低。
-- ⚠️ 只有主题真的存在（有音源且有 clip）才压低日常 BGM —— 否则玩家只听到
-- 日常 BGM 突然变小声、什么都没换上，像设备出了毛病。主题不放就不动音量。
local function StartBGM()
    local theme = AudioSrc("BGM_Ceremony")
    if theme == nil or theme.clip == nil then return end
    pcall(function() theme:Play() end)
    local amb = AudioSrc("BGM_Ambient")
    if amb ~= nil then
        pcall(function() amb.volume = 0.18 end)
        print("[CampusCeremony] 典礼主题起，日常 BGM 已压低")
    end
end

local function FireworkSfx()
    local sfx = AudioSrc("SFX_Firework")
    if sfx == nil or sfx.clip == nil then return end
    pcall(function() sfx:Play() end)
end

-- 加一个粒子动画。t0 可以比现在晚（升空弹落地后才爆），t < 0 期间保持隐藏。
local function AddAnim(tf, p0, v0, t0, life, s0)
    if tf == nil then return end
    tf.gameObject:SetActive(false)
    anims[#anims + 1] = { tf = tf, p0 = p0, v0 = v0, t0 = t0, life = life, s0 = s0 }
end

-- 一发烟花：先升空，到顶再爆散
local function FireShot(now)
    -- ⚠️ 计数必须先做，不能放在"有没有节点"的判断之后。
    -- 万一场景里没有烟花节点（构建漏了 / 被别人删了），提前 return 会让 shotsFired
    -- 永远停在 0，而收尾条件是 shotsFired >= MAX_SHOTS —— 典礼就永远卡在"进行中"，
    -- 既不会结束也不会写标记，玩家看到一条开演提示之后再无下文。
    shotsFired = shotsFired + 1

    -- 声音先于画面判定：就算场景里没有烟花节点（视觉被降级），
    -- 这一发"响"依然成立 —— 典礼此刻确实发生了。
    FireworkSfx()

    if rocket == nil or #sparks == 0 then
        print(string.format("[CampusCeremony] 第 %d 发（无烟花节点，跳过）", shotsFired))
        return
    end

    -- 落点：广场上方一圈，离中心 5~13m，高 8~13m
    local ang = math.random() * math.pi * 2
    local rad = 5.0 + math.random() * 8.0
    local bx = math.cos(ang) * rad
    local bz = math.sin(ang) * rad
    local by = 8.0 + math.random() * 5.0

    -- 升空：从地面附近的基座位置垂直上去
    local startY = 0.8
    local riseSpeed = (by - startY) / ROCKET_LIFE
    AddAnim(rocket, V(bx, startY, bz), V(0, riseSpeed, 0),
        now, ROCKET_LIFE, 1.0)

    -- 爆散：仰角随机一点，避免每发都是一个正球
    local burstAt = now + ROCKET_LIFE
    for i = 1, math.min(SPARK_COUNT, #sparks) do
        local a = (i / SPARK_COUNT) * math.pi * 2 + (math.random() - 0.5) * 0.45
        local el = math.random() * 1.1 - 0.25
        local sp = 3.2 + math.random() * 2.6
        local vx = math.cos(a) * math.cos(el) * sp
        local vz = math.sin(a) * math.cos(el) * sp
        local vy = math.sin(el) * sp
        AddAnim(sparks[i], V(bx, by, bz), V(vx, vy, vz),
            burstAt, SPARK_LIFE, 1.0)
    end

    print(string.format("[CampusCeremony] 第 %d 发，落点 (%.1f, %.1f, %.1f)", shotsFired, bx, by, bz))
end

local function Start()
    if playing then return end
    playing = true
    shotsFired = 0
    local now = Now()
    nextShotAt = now + FIREWORK_DELAY

    -- 她来不来，取决于好感是否满档。
    -- 这是第 4 档那句「毕业典礼那天，我陪你去」真正的约束 —— 不满档她不会来，
    -- 广场上只有烟花。否则她说的话和实际发生的事对不上，又成了一句空话。
    local star = _G["CampusStar"]
    local sheComes = false
    if star ~= nil and star.OnCeremony ~= nil and star.IsMax ~= nil then
        local ok, isMax = pcall(star.IsMax, star)
        if ok and isMax then
            sheComes = true
            pcall(star.OnCeremony, star)
        end
    end

    if sheComes then
        Toast("毕业典礼开始了 · 她也来了")
    else
        Toast("毕业典礼开始了")
    end
    StartBGM()
    print("[CampusCeremony] 开演，她" .. (sheComes and "来了" or "没来（好感未满）"))
end

local function Finish()
    playing = false
    local save = _G["CampusSave"]
    if save ~= nil and save.Ready() then
        save.Set("ceremony", 1)
        save.Flush(true)
    end
    Toast("典礼结束 · 谢谢你把八枚校徽找回来")
    print("[CampusCeremony] 演出结束，已记录 ceremony=1")
end

-- ---------------------------------------------------------------- 帧驱动

local lastFrame = -1

local function Tick()
    local f = CS.UnityEngine.Time.frameCount
    if f == nil then f = Now() end
    if f == lastFrame then return end
    lastFrame = f

    -- ---- 1. 判定要不要开演 ----
    if not playing then
        local q = _G["CampusQuest"]
        if q == nil or q.IsComplete == nil or not q:IsComplete() then
            return
        end

        local save = _G["CampusSave"]
        if save ~= nil and save.Ready() then
            -- 已经看过就不重播。旧存档没有 c 字段 → 读到 0 → 补播一次
            if save.Get("ceremony", 0) ~= 0 then return end
            Start()
        else
            -- 存档层还没就绪（Awake 顺序不保证）：等一下。
            -- 等太久还没好就直接演 —— 宁可多演一次，也不能让玩家什么都看不到。
            local now = Now()
            if waitSaveAt == 0 then waitSaveAt = now end
            if now - waitSaveAt > SAVE_WAIT then
                print("[CampusCeremony] 存档层未就绪，直接开演（不记标记）")
                Start()
            end
        end
        return
    end

    -- ---- 2. 放下一发 ----
    local now = Now()
    if shotsFired < MAX_SHOTS and now >= nextShotAt then
        FireShot(now)
        nextShotAt = now + SHOT_GAP
    end

    -- ---- 3. 推进粒子 ----
    for i = #anims, 1, -1 do
        local a = anims[i]
        local t = now - a.t0
        if t >= a.life then
            a.tf.gameObject:SetActive(false)
            table.remove(anims, i)
        elseif t >= 0 then
            a.tf.gameObject:SetActive(true)
            local x = a.p0.x + a.v0.x * t
            local y = a.p0.y + a.v0.y * t + 0.5 * GRAVITY * t * t
            local z = a.p0.z + a.v0.z * t
            a.tf.position = V(x, y, z)
            -- 越飞越小：加法光效靠尺寸传达"衰减"，没有 alpha 可调
            local k = 1.0 - t / a.life
            local s = a.s0 * (0.2 + 0.8 * k)
            a.tf.localScale = V(s, s, s)
        end
    end

    -- ---- 4. 收尾 ----
    if shotsFired >= MAX_SHOTS and #anims == 0 then
        Finish()
    end
end

-- ---------------------------------------------------------------- 生命周期

function Awake()
    group = nil
    rocket = nil
    sparks = {}
    anims = {}
    playing = false
    shotsFired = 0
    nextShotAt = 0
    waitSaveAt = 0
    lastFrame = -1

    -- Fireworks 根节点必须常驻 active（Find 才看得到），隐藏的是它的子物体
    local ok, go = pcall(function() return CS.UnityEngine.GameObject.Find("Fireworks") end)
    if ok and go ~= nil then
        group = go.transform
        rocket = group:Find("Firework_Rocket")
        for i = 1, SPARK_COUNT do
            local sp = group:Find(string.format("Firework_Spark%02d", i))
            if sp ~= nil then sparks[#sparks + 1] = sp end
        end
        -- 初始全熄
        if rocket ~= nil then rocket.gameObject:SetActive(false) end
        for i = 1, #sparks do sparks[i].gameObject:SetActive(false) end
    end

    print(string.format("[CampusCeremony] ready, group=%s rocket=%s sparks=%d",
        tostring(group ~= nil), tostring(rocket ~= nil), #sparks))
end

function Update()     Tick() end
function LateUpdate() Tick() end
function OnUpdate()   Tick() end
