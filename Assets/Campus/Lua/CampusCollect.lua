-- 校园「校徽收集」：把拾取到的 Collect_xx 带到陈列架前的交付区，自动入柜
--
-- 事件名一律对齐 SDK 自己的示例脚本 DouyinPickup.lua：
--   OnPlayerTriggerEnter(douyinPlayer)  玩家collider进入本物体的触发器时派发（道具侧用这个）
--   OnActorTriggerEnter(actor)          角色自身进入别人触发器时派发（备用，见文末说明）
--   actor.isLocal / actor:GetPickupInHand(CS.HandType.All) / actor:Drop(go)
-- 所有引用运行时按名字查找，不依赖 ---@var 绑定数据。
--
-- ⚠️ 三条踩过的坑，改脚本时别踩回去：
--   1. GameObject.Find 找不到 active=false 的物体 —— 所以 Plaza_Reward 根节点常驻激活，
--      隐藏的是它的子物体，集齐后逐个打开。
--   2. GetPickupInHand 必须传 CS.HandType.All；不传参相当于拿 nil 去转枚举。
--   3. 拾取物脚本默认 DropDestroy=true —— 放下 5 秒后会自动 NetDestroy。徽章摆上架就消失。
--      构建时已把 8 个拾取物的 DropDestroy 改成 false，这里再兜一次底。

local ITEM_PREFIX = "Collect_"
local SHELF_NAME  = "CollectShelf"
local REWARD_NAME = "Plaza_Reward"
local TOTAL       = 8

local doneCount = 0
local isDone = {}

-- 前向声明：QuestApi.Accept 定义在下面，但那会儿 SyncSave 还没声明，
-- 不提前 local 的话闭包里会被解析成全局 nil
local SyncSave

-- ===== 任务状态 =====
-- 架构参考同平台开源项目 XiaoHuoRen_EggRescue（仓库无 LICENSE，只借鉴"全局管理器 +
-- 条件分支 + 触发即改变量"的思路，代码全部自己重写）与 SDK 自带 DouyinDataStore 示例。
-- 不新增场景对象：状态就挂在收集脚本上，NPC 通过 _G["CampusQuest"] 查询。
local questAccepted = false
local stage = "idle"          -- idle / collecting / done
local emblemFound = {}

local function FindGo(name)
    return CS.UnityEngine.GameObject.Find(name)
end

local function SlotOf(index)
    local shelf = FindGo(SHELF_NAME)
    if shelf == nil then
        return nil
    end
    return shelf.transform:Find(string.format("Slot_%02d", index))
end

local function LightSlot(index)
    local slot = SlotOf(index)
    if slot == nil then
        return
    end
    local glow = slot:Find("Glow")
    if glow ~= nil then
        glow.gameObject:SetActive(true)
    end
end

local function Toast(msg)
    local ok = pcall(function()
        CS.DouyinUtility.Toast(msg)
    end)
    if not ok then
        print(msg)
    end
end

-- ---------------------------------------------------------------- 任务 API
-- 对外只读查询 + 一个 Accept()。NPCTalk.lua 用 _G["CampusQuest"] 拿它。
local QuestApi = {}

function QuestApi.Count() return doneCount end
function QuestApi.Total() return TOTAL end
-- 注意：这两个方法带参数，必须显式写 self —— 调用方用的是冒号语法 `quest:Has(i)`，
-- 不写 self 的话第一个实参会被当 self 吃掉，index/npcId 永远拿到表本身。
function QuestApi.Has(self, index) return emblemFound[index] == true end
function QuestApi.IsAccepted() return questAccepted end
function QuestApi.IsComplete() return doneCount >= TOTAL end
function QuestApi.Stage() return stage end

function QuestApi.Accept()
    if questAccepted then return end
    questAccepted = true
    stage = "collecting"
    Toast("任务：集齐 8 枚校徽，交给门厅陈列架")
    print("[CampusQuest] accepted")
    SyncSave()
end

-- 线索表：NPC → 该优先说的台词序号（1 基，对应 NpcLines.txt 的出现顺序）。
-- 只在"任务进行中 + 这次刚靠近"时插一句，日常轮播仍是前 4 句。
local HINT_LINE = {
    NPC_01 = 3,   -- 听说集齐八枚，广场地标会亮
    NPC_03 = 2,   -- 广场中间的台子
    NPC_04 = 4,   -- 球门那边好像有一枚
    NPC_05 = 4,   -- 三层阅览角
    NPC_06 = 3,   -- 二楼走廊尽头还有个柜子
}

function QuestApi.HintLine(self, npcId)
    if not questAccepted or doneCount >= TOTAL then return nil end
    return HINT_LINE[npcId]
end

-- 奖励根节点保持激活（否则 Find 不到），子物体才是真正点亮的部分
local function ShowReward()
    local reward = FindGo(REWARD_NAME)
    if reward == nil then
        print("[CampusCollect] 未找到 " .. REWARD_NAME)
        return
    end
    local t = reward.transform
    for i = 0, t.childCount - 1 do
        t:GetChild(i).gameObject:SetActive(true)
    end
end

-- 冻结并摆到槽位：用世界坐标，不做 SetParent（避开 XLua 对 SetParent 重载的解析差异）
local function FreezeTo(item, slot)
    local rb = item:GetComponent(typeof(CS.UnityEngine.Rigidbody))
    if rb ~= nil then
        rb.isKinematic = true
        rb.useGravity = false
    end
    if slot ~= nil then
        item.transform.position = slot.position
        item.transform.rotation = slot.rotation
    end
    local cols = item:GetComponentsInChildren(typeof(CS.UnityEngine.Collider))
    for i = 0, cols.Length - 1 do
        cols[i].enabled = false
    end
    -- 摆上架之后这枚徽章不再参与拾取交互
    local script = item:GetComponent(typeof(CS.DouyinScript))
    if script ~= nil then
        script.enabled = false
    end
end

local function TryCollect(actor)
    if actor == nil then
        return
    end
    if actor.isLocal == false then
        return
    end

    local item = actor:GetPickupInHand(CS.HandType.All)
    if item == nil then
        return
    end

    local index = tonumber(string.match(item.name, ITEM_PREFIX .. "(%d+)"))
    if index == nil or isDone[index] == true then
        return
    end

    local slot = SlotOf(index)
    if slot == nil then
        print("[CampusCollect] 缺少槽位 Slot_" .. string.format("%02d", index))
        return
    end

    isDone[index] = true
    emblemFound[index] = true
    doneCount = doneCount + 1

    -- 玩家先捡到再找老陈也不会卡住：第一枚自动把任务置为进行中
    if not questAccepted then
        questAccepted = true
        stage = "collecting"
    end

    actor:Drop(item)
    FreezeTo(item, slot)
    LightSlot(index)

    print(string.format("[CampusCollect] %s 已入柜 (%d/%d)", item.name, doneCount, TOTAL))
    Toast(string.format("校徽 %d/%d", doneCount, TOTAL))

    if doneCount >= TOTAL then
        stage = "done"
        ShowReward()
        print("[CampusCollect] 全部集齐，广场地标已点亮")
        Toast("八枚校徽集齐！去广场看毕业典礼")
    end

    SyncSave()
end

-- ---------------------------------------------------------------- 存档
-- 存档层在 CampusSave.lua（挂在独立宿主上）。它异步读 DataStore，读到了才回调这里。
-- 两个必须守住的点：
--   1. **取并集**，不是覆盖。读档通常比 Awake 晚十几帧，这期间玩家可能已经捡了一枚；
--      直接赋值会把那枚抹掉，还会让 doneCount 和 isDone 对不上。
--   2. **读不到就不写**。CampusSave 自己会挡住（ready=false 时 WriteNow 直接返回），
--      这里不用再判一次，但别绕过它直接调 manager。

-- 把存档里"已入柜"的校徽摆回架子：直接用 FreezeTo，玩家重进世界看到的是
-- 校徽已经在陈列架上，而不是凭空消失。FreezeTo 会禁用 DouyinScript，捡不起来。
local function Restore()
    local save = _G["CampusSave"]
    if save == nil then return end

    local bits = save.Get("emblems", "")
    local restored = 0

    for i = 1, TOTAL do
        if isDone[i] ~= true and string.sub(bits, i, i) == "1" then
            isDone[i] = true
            emblemFound[i] = true
            doneCount = doneCount + 1
            restored = restored + 1

            local item = FindGo(string.format(ITEM_PREFIX .. "%02d", i))
            local slot = SlotOf(i)
            if item ~= nil and slot ~= nil then
                FreezeTo(item, slot)
            elseif item ~= nil then
                item:SetActive(false)     -- 没有槽位就只藏起来，别把徽章留在场上
            end
            LightSlot(i)
        end
    end

    if save.Get("quest", 0) == 1 or doneCount > 0 then
        questAccepted = true
        if stage == "idle" then stage = "collecting" end
    end
    if doneCount >= TOTAL then
        stage = "done"
        ShowReward()
    end

    print(string.format("[CampusCollect] 存档恢复 %d 枚（共 %d/%d, quest=%s, stage=%s）",
        restored, doneCount, TOTAL, tostring(questAccepted), stage))

    -- ⚠️ 必须回写一次。读档比 Awake 晚十几帧，玩家可能已经在这期间捡了校徽；
    -- 那次 SyncSave 因为 ready=false 被存档层挡掉了。如果这里不补写，内存位图会
    -- 停在"存档值"，而定期写又因为"内容没变化"直接跳过 —— 那枚就永久丢了。
    -- 内容真的一致时 WriteNow 会自己短路，不会白写一次。
    SyncSave()
end

function SyncSave()
    local save = _G["CampusSave"]
    if save == nil then return end
    local bits = {}
    for i = 1, TOTAL do
        bits[i] = isDone[i] and "1" or "0"
    end
    save.Set("emblems", table.concat(bits))
    save.Set("quest", (questAccepted or doneCount > 0) and 1 or 0)
    save.Flush(true)     -- 入柜是低频事件（最多 8 次），强制立刻落盘
end

-- CampusSave 的 Awake 可能比本脚本晚（场景对象顺序不保证），
-- 所以 Awake 里试一次，没挂上就靠 LateUpdate 补挂。
local saveHooked = false

local function TryHookSave()
    if saveHooked then return end
    local save = _G["CampusSave"]
    if save == nil then return end
    saveHooked = true
    save.OnReady(Restore)
end

function Awake()
    doneCount = 0
    isDone = {}
    questAccepted = false
    stage = "idle"
    emblemFound = {}
    saveHooked = false
    _G["CampusQuest"] = QuestApi
    TryHookSave()
    print("[CampusCollect] ready, total=" .. TOTAL .. " (CampusQuest registered)")
end

function OnDestroy()
    if _G["CampusQuest"] == QuestApi then
        _G["CampusQuest"] = nil
    end
end

-- 道具侧（本物体是触发器）走这个：玩家 collider 进入时派发
function OnPlayerTriggerEnter(douyinPlayer)
    if douyinPlayer == nil then
        return
    end
    local actor = douyinPlayer:GetActor()
    TryCollect(actor)
end

-- 备用通道：角色侧派发。两个都挂是因为 XLua 对未定义函数静默跳过，
-- 一旦哪个事件名在运行时不存在，另一个还能兜住；重复进入由 isDone 挡掉。
function OnActorTriggerEnter(actor)
    TryCollect(actor)
end

-- ---------------------------------------------------------------- 帧驱动
-- 只为补挂存档：CampusSave 的 Awake 可能比本脚本晚。挂上之后 TryHookSave
-- 第一行就 return，开销可以忽略。帧号去重，理由同 NPCTalk.lua。

local lastFrame = -1

local function Tick()
    local f = CS.UnityEngine.Time.frameCount
    if f == nil then f = CS.UnityEngine.Time.time end
    if f == lastFrame then return end
    lastFrame = f
    TryHookSave()
end

function Update()     Tick() end
function LateUpdate() Tick() end
function OnUpdate()   Tick() end
