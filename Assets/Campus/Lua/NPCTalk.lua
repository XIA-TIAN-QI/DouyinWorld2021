-- 校园 NPC：沿路点走路，玩家靠近就停下来搭话
--
-- 挂在 NPC_01..07 的 DouyinScript 上（构建脚本 BuildNPCs 自动挂），子物体结构：
--   Model/ArmL, ArmR, LegL, LegR   四肢枢轴（行走时绕 x 轴前后摆）
--   Label                          头顶名牌，每帧 billboard 朝向相机
--   Label/NameQuad                 名字（贴图 quad，常显）
--   Label/Bubble/Line_01..N        每句台词一个 quad，只打开当前这句
--   Path/Waypoint_01..N            路点（世界坐标，循环）
--
-- 台词不是运行时文本，而是预先画进 T_NpcLines.png 的图集里（见 _tools/make_npc_lines.py）。
-- 原因是 TextMesh 用的 GUI/Text Shader 在 URP 下根本不渲染；贴图 quad 走 World_Lit，
-- 和校名牌同一条管线，真机和离屏截图都能看到。
-- 代价：改台词要改 Assets/Campus/NpcLines.txt 再重跑图集脚本 + 重建场景。
--
-- 不依赖 ---@var 绑定，全部运行时按名字查找（同 CampusCollect.lua 的做法）。
-- 行走不用 NavMesh：路径是构建时摆死的折线，没有寻路需求。

local TALK_RANGE  = 3.2    -- 进入这个距离就停下来搭话
local LEAVE_RANGE = 4.6    -- 超出这个距离恢复走路（留 1.4m 回差，避免在边界抖动）
local TALK_GAP    = 6.5    -- 两句之间的间隔
local BUBBLE_TIME = 4.2    -- 一句话在气泡里停留多久
local ARRIVE_EPS  = 0.30   -- 到点判定
local TURN_RATE   = 7.0    -- 转向插值速度

local id
local speed = 1.0

-- ===== 任务线选句 =====
-- 老陈（NPC_07）的 5~7 句只在对应阶段说，不进日常轮播（平时只轮 1~4 句）。
-- 其他 NPC 靠近时优先插一句线索（由 CampusCollect.lua 的 _G["CampusQuest"] 提供）。
local QUEST_LINES = {
    NPC_07 = { offer = 5, mid = 6, done = 7 },
}
local normalMax = 0          -- 日常轮播上限
local pendingSpecial = true  -- 这次靠近还没插过任务/线索句

local root, model
local armL, armR, legL, legR
local label, bubble
local lines = {}          -- Bubble 下的 Line_xx
local waypoints = {}

local wpIndex = 1
local lineIndex = 1
local phase = 0
local talking = false
local nextLineAt = 0
local bubbleHideAt = 0

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
    if bubble ~= nil then
        bubble.gameObject:SetActive(false)
    end
end

-- 台词配音：音源直接挂在 quad 上（构建脚本按 Voice/<NPC>/<quad>.ogg 有文件才挂），
-- 气泡隐藏时 Unity 自动停声。全程 pcall：音频在真机上未验证，缺什么都不拖垮气泡。
local function PlayVoice(q)
    pcall(function()
        local src = q.gameObject:GetComponent(typeof(CS.UnityEngine.AudioSource))
        if src ~= nil and src.clip ~= nil then src:Play() end
    end)
end

-- 只开第 i 句的 quad：图集方案下换台词 = 换显隐，没有文本可改
local function Say(i)
    if bubble == nil or #lines == 0 then return end
    if i < 1 then i = 1 end
    if i > #lines then i = #lines end
    for k = 1, #lines do
        lines[k].gameObject:SetActive(k == i)
    end
    bubble.gameObject:SetActive(true)
    bubbleHideAt = CS.UnityEngine.Time.time + BUBBLE_TIME
    PlayVoice(lines[i])
end

-- 四肢摆到指定角度（度）
local function Pose(amount)
    local swing = math.sin(phase) * amount
    if legL ~= nil then legL.localRotation = CS.UnityEngine.Quaternion.Euler(swing, 0, 0) end
    if legR ~= nil then legR.localRotation = CS.UnityEngine.Quaternion.Euler(-swing, 0, 0) end
    if armL ~= nil then armL.localRotation = CS.UnityEngine.Quaternion.Euler(-swing * 0.85, 0, 0) end
    if armR ~= nil then armR.localRotation = CS.UnityEngine.Quaternion.Euler(swing * 0.85, 0, 0) end
    if model ~= nil then
        model.localPosition = CS.UnityEngine.Vector3(0, math.abs(math.sin(phase)) * 0.022, 0)
    end
end

local function ResetPose()
    for _, t in ipairs({ legL, legR, armL, armR }) do
        if t ~= nil then t.localRotation = CS.UnityEngine.Quaternion.identity end
    end
    if model ~= nil then
        model.localPosition = CS.UnityEngine.Vector3(0, 0, 0)
    end
end

local function FaceTo(dx, dz, dt)
    if math.abs(dx) + math.abs(dz) < 0.0001 then return end
    local want = CS.UnityEngine.Quaternion.LookRotation(CS.UnityEngine.Vector3(dx, 0, dz))
    root.rotation = CS.UnityEngine.Quaternion.Slerp(root.rotation, want, math.min(1, dt * TURN_RATE))
end

-- ---------------------------------------------------------------- 行走

local function Walk(dt)
    if #waypoints == 0 then return end
    local target = waypoints[wpIndex].position
    local pos = root.position

    local dx, dz = target.x - pos.x, target.z - pos.z
    local d = math.sqrt(dx * dx + dz * dz)
    if d < ARRIVE_EPS then
        wpIndex = wpIndex % #waypoints + 1
        return
    end

    local step = speed * dt
    if step > d then step = d end
    local nx, nz = dx / d, dz / d

    -- 高度直接跟路点走：室内路点在 F1、室外在 0，
    -- 避免逐帧累加浮点误差慢慢陷进地面
    root.position = CS.UnityEngine.Vector3(pos.x + nx * step, target.y, pos.z + nz * step)
    FaceTo(nx, nz, dt)

    phase = phase + step * 3.4
    Pose(24)
end

-- ---------------------------------------------------------------- 搭话

-- 任务阶段句：老陈专用。返回 1 基台词序号或 nil
local function QuestSpecialLine()
    local quest = _G["CampusQuest"]
    local q = QUEST_LINES[id]
    if q == nil or quest == nil or quest.IsComplete == nil then
        return nil
    end
    if not quest:IsAccepted() then
        if q.offer <= #lines then return q.offer end
        return nil
    end
    if quest:IsComplete() then
        if q.done <= #lines then return q.done end
        return nil
    end
    if quest:Count() == 0 and q.mid <= #lines then
        return q.mid
    end
    return nil
end

-- 线索句：其他 NPC 专用。只在任务进行中、这次刚靠近时插一句
local function QuestHintLine()
    local quest = _G["CampusQuest"]
    if quest == nil or quest.HintLine == nil then
        return nil
    end
    local idx = quest:HintLine(id)
    if idx ~= nil and idx >= 1 and idx <= normalMax then
        return idx
    end
    return nil
end

local function Talk(dt, playerPos)
    local pos = root.position
    FaceTo(playerPos.x - pos.x, playerPos.z - pos.z, dt * 1.4)
    ResetPose()

    local now = CS.UnityEngine.Time.time
    if now >= nextLineAt then
        local special = nil
        if pendingSpecial then
            pendingSpecial = false
            special = QuestSpecialLine()
            if special == nil then
                special = QuestHintLine()
            end
        end

        if special ~= nil then
            Say(special)
            -- 老陈把任务说出口之后正式接取（Say 只负责显示）
            local q = QUEST_LINES[id]
            local quest = _G["CampusQuest"]
            if q ~= nil and quest ~= nil and quest.Accept ~= nil
                and special == q.offer and not quest:IsAccepted() then
                quest:Accept()
            end
        else
            Say(lineIndex)
            lineIndex = lineIndex % math.max(1, normalMax) + 1
        end
        nextLineAt = now + TALK_GAP
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

    -- 台词 quad：按名字排序，保证 Line_01 就是第一句
    lines = {}
    if bubble ~= nil then
        for i = 0, bubble.childCount - 1 do
            lines[#lines + 1] = bubble:GetChild(i)
        end
        table.sort(lines, function(a, b) return a.name < b.name end)
    end

    -- 路点
    local pathRoot = FindChild(root, "Path")
    if pathRoot ~= nil then
        local list = {}
        for i = 0, pathRoot.childCount - 1 do
            list[#list + 1] = pathRoot:GetChild(i)
        end
        table.sort(list, function(a, b) return a.name < b.name end)
        waypoints = list
    end

    id = self.gameObject.name
    normalMax = #lines
    local q = QUEST_LINES[id]
    if q ~= nil and q.offer > 1 then
        normalMax = math.min(#lines, q.offer - 1)
    end
    wpIndex = 1
    phase = 0
    talking = false
    lineIndex = 1
    pendingSpecial = true
    nextLineAt = 0
    bubbleHideAt = 0
    HideBubble()

    print(string.format("[NPCTalk] %s ready, waypoints=%d lines=%d",
        tostring(id), #waypoints, #lines))
end

-- ---------------------------------------------------------------- 帧驱动
--
-- ⚠️ 踩过的坑：SDK 的 DouyinScript 只有一个 autoUpdate 开关，但官方示例
-- （DouyinPickup.lua / DouyinSeat.lua）里唯一的帧回调是 LateUpdate()，没有 Update()。
-- 所以这里把 Update / LateUpdate / OnUpdate 三个入口全挂上，用 frameCount 去重 ——
-- 命中哪个都能跑，两个都被派发时也只跑一次。
-- 日志里 `via=` 会打出实际生效的那个；确认之后可以只留一条。

local lastFrame = -1
local tickCount = 0
local tickVia = nil
local diagCount = 0

local function Diag(tag, playerPos, d, dt)
    if diagCount >= 14 then return end
    diagCount = diagCount + 1
    local fc = CS.UnityEngine.Time.frameCount
    if fc == nil then fc = -1 end
    print(string.format("[NPCTalk] %s %s tick=%d via=%s frame=%d dt=%.3f player=%s d=%s",
        tostring(root ~= nil and root.name or "?"), tag, tickCount, tostring(tickVia),
        fc, dt,
        playerPos ~= nil and string.format("(%.2f,%.2f,%.2f)", playerPos.x, playerPos.y, playerPos.z) or "nil",
        d ~= nil and string.format("%.2f", d) or "nil"))
end

local function Tick(dt, source)
    local f = CS.UnityEngine.Time.frameCount
    if f == nil then f = CS.UnityEngine.Time.time end   -- 兜底：没有 frameCount 的宿主用时间戳去重
    if f == lastFrame then return end      -- Update 和 LateUpdate 都派发时，同一帧只算一次
    lastFrame = f
    tickCount = tickCount + 1
    if tickVia == nil then tickVia = source end

    if dt <= 0 then return end
    if dt > 0.2 then dt = 0.2 end      -- 卡帧时别一步跨半米

    -- 名牌正对相机：quad 正面朝 +Z，所以让 +Z 指向相机
    local cam = CS.UnityEngine.Camera.main
    if label ~= nil and cam ~= nil then
        local away = label.position - cam.transform.position
        if away.sqrMagnitude > 0.0001 then
            label.rotation = CS.UnityEngine.Quaternion.LookRotation(away)
        end
    end

    -- 气泡到点就收
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

    -- 探针：头两帧 + 之后每 300 帧一条，足够看清回调有没有跑、玩家离多远
    if tickCount <= 2 or (tickCount % 300 == 0) then
        Diag(tickCount <= 2 and "启动" or "周期", playerPos, d, dt)
    end

    if d ~= nil and d <= TALK_RANGE then
        if not talking then
            talking = true
            nextLineAt = 0            -- 一靠近就说第一句
            pendingSpecial = true     -- 这次靠近允许插一句任务/线索
        end
        Talk(dt, playerPos)
    elseif talking and d ~= nil and d < LEAVE_RANGE then
        ResetPose()                   -- 回差带里：先别急着走，站在原地
    else
        talking = false
        Walk(dt)
    end
end

-- ---------------------------------------------------------------- 入口
-- 三个名字都绑到同一个 Tick（帧号去重），谁被 SDK 派发都能动。

function Update()     Tick(CS.UnityEngine.Time.deltaTime, "Update")     end
function LateUpdate() Tick(CS.UnityEngine.Time.deltaTime, "LateUpdate") end
function OnUpdate()   Tick(CS.UnityEngine.Time.deltaTime, "OnUpdate")   end
