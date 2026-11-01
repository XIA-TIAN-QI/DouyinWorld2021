-- 黄思诚：女主角。和 NPCTalk.lua 那几个"路过的人"不是一套逻辑 ——
-- 她不巡逻，她等你：发现玩家就主动迎上来，玩家走动就跟着，走太远才回原位。
--
-- 挂在 NPC_08 的 DouyinScript 上（构建脚本 BuildStar 自动挂），子物体结构：
--   Model/ArmL, ArmR, LegL, LegR   四肢枢轴
--   Model                          整体（待机时做重心偏移，别让站姿像根柱子）
--   Label / Label/Bubble/Line_xx   名牌与台词（贴图 quad，见 NPCTalk.lua 顶部注释）
--   Path/Waypoint_01               待机点
--
-- 台词同样是预渲染图集（T_NpcLines.png），脚本只切显隐。
-- 不用 NavMesh：她只在校门→广场这段活动，直线走就够；
-- 玩家上楼/进教学楼她跟不进去（同层判定会让她放弃），这是刻意的 —— 她没有寻路能力，
-- 硬追只会贴着墙根原地磨。

local NOTICE     = 14.0   -- 进入这个距离：发现玩家，主动过来
local TALK_RANGE = 2.60   -- 进入这个距离：开始说话。**注意它只控制"说不说"，不控制"走不走"** ——
                          -- 走路的下限是 STOP_AT(1.9)。两个用途用同一个数，她就会在 2.6m 站住不走了
local GIVEUP     = 22.0   -- 超出这个距离：放弃，回原位
local STOP_AT    = 1.9    -- 追到离玩家这么近就停（不贴脸）
local SPEED      = 2.10   -- 比普通 NPC 快一点，否则跟不上走路的玩家
local TURN_RATE  = 8.0
local TALK_GAP   = 4.6    -- 两句之间的间隔（她话密，比路人快）
local BUBBLE_TIME= 4.5
local ARRIVE_EPS = 0.35
local LEVEL_EPS  = 1.0    -- 高度差超过这个就算"换了楼层"，不追

-- 活动范围：只在校门 → 广场这一带。她不会冲进教学楼、也不会跑到操场去
local AREA_X = 13.0
local AREA_Z_MIN, AREA_Z_MAX = -24.0, 12.0

local Q = CS.UnityEngine.Quaternion
local V = CS.UnityEngine.Vector3

local root, model
local armL, armR, legL, legR
local label, bubble
local lines = {}
local home

local phase = 0
local lineIndex = 1
local nextLineAt = 0
local bubbleHideAt = 0
local engaged = false

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

local function FlatDist(a, b)
    local dx, dz = a.x - b.x, a.z - b.z
    return math.sqrt(dx * dx + dz * dz)
end

local function HideBubble()
    if bubble ~= nil then bubble.gameObject:SetActive(false) end
end

local function Say(i)
    if bubble == nil or #lines == 0 then return end
    if i < 1 then i = 1 end
    if i > #lines then i = #lines end
    for k = 1, #lines do
        lines[k].gameObject:SetActive(k == i)
    end
    bubble.gameObject:SetActive(true)
    bubbleHideAt = CS.UnityEngine.Time.time + BUBBLE_TIME
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

local function MoveTo(target, dt, stopAt)
    local pos = root.position
    local dx, dz = target.x - pos.x, target.z - pos.z
    local d = math.sqrt(dx * dx + dz * dz)
    if d < stopAt then
        PoseIdle(CS.UnityEngine.Time.time)
        return true
    end

    local step = SPEED * dt
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

local function ChaseTo(playerPos, dt)
    local target = ClampTarget(playerPos)
    local moved = MoveTo(target, dt, STOP_AT)
    -- 走到边上了（玩家在范围外）：站着等，但脸朝玩家
    if moved then
        FaceTo(playerPos.x - root.position.x, playerPos.z - root.position.z, dt * 1.2)
    end
end

-- 只说不动：是否走到位由 Update 里的 STOP_AT 判断，两个距离不能混用
local function TrySay()
    local now = CS.UnityEngine.Time.time
    if now < nextLineAt then return end
    Say(lineIndex)
    lineIndex = lineIndex % math.max(1, #lines) + 1
    nextLineAt = now + TALK_GAP
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

    lines = {}
    if bubble ~= nil then
        for i = 0, bubble.childCount - 1 do
            lines[#lines + 1] = bubble:GetChild(i)
        end
        table.sort(lines, function(a, b) return a.name < b.name end)
    end

    local pathRoot = FindChild(root, "Path")
    if pathRoot ~= nil and pathRoot.childCount > 0 then
        home = pathRoot:GetChild(0).position
    end

    phase = 0
    lineIndex = 1
    nextLineAt = 0
    bubbleHideAt = 0
    engaged = false
    HideBubble()

    print(string.format("[CampusStar] %s ready, lines=%d, home=%s",
        tostring(root.name), #lines, home ~= nil and tostring(home) or "nil"))
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
    print(string.format("[CampusStar] %s %s tick=%d via=%s frame=%d dt=%.3f player=%s d=%s engaged=%s",
        tostring(root ~= nil and root.name or "?"), tag, tickCount, tostring(tickVia),
        fc, dt,
        playerPos ~= nil and string.format("(%.2f,%.2f,%.2f)", playerPos.x, playerPos.y, playerPos.z) or "nil",
        d ~= nil and string.format("%.2f", d) or "nil",
        tostring(engaged)))
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

    -- 名牌正对相机（quad 正面朝 +Z）
    local cam = CS.UnityEngine.Camera.main
    if label ~= nil and cam ~= nil then
        local away = label.position - cam.transform.position
        if away.sqrMagnitude > 0.0001 then
            label.rotation = Q.LookRotation(away)
        end
    end

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

    if tickCount <= 2 or (tickCount % 300 == 0) then
        Diag(tickCount <= 2 and "启动" or "周期", playerPos, d, dt)
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
        GoHome(dt)
        return
    end

    -- 走路：一直走到 STOP_AT(1.9) 才停 —— 她会真的走到你身边，不是隔着三米喊话
    if d <= STOP_AT then
        FaceTo(playerPos.x - root.position.x, playerPos.z - root.position.z, dt * 1.4)
        PoseIdle(CS.UnityEngine.Time.time)
    else
        ChaseTo(playerPos, dt)
    end

    -- 说话：TALK_RANGE(2.6) 内就开口（比停止距离大 0.7，留一点回差）
    if d <= TALK_RANGE then
        TrySay()
    end
end

-- ---------------------------------------------------------------- 入口

function Update()     Tick(CS.UnityEngine.Time.deltaTime, "Update")     end
function LateUpdate() Tick(CS.UnityEngine.Time.deltaTime, "LateUpdate") end
function OnUpdate()   Tick(CS.UnityEngine.Time.deltaTime, "OnUpdate")   end
