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
end

function Awake()
    doneCount = 0
    isDone = {}
    questAccepted = false
    stage = "idle"
    emblemFound = {}
    _G["CampusQuest"] = QuestApi
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
