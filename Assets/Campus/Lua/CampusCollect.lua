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
    doneCount = doneCount + 1

    actor:Drop(item)
    FreezeTo(item, slot)
    LightSlot(index)

    print(string.format("[CampusCollect] %s 已入柜 (%d/%d)", item.name, doneCount, TOTAL))
    Toast(string.format("校徽 %d/%d", doneCount, TOTAL))

    if doneCount >= TOTAL then
        ShowReward()
        print("[CampusCollect] 全部集齐，广场地标已点亮")
        Toast("校徽集齐！广场地标已点亮")
    end
end

function Awake()
    doneCount = 0
    isDone = {}
    print("[CampusCollect] ready, total=" .. TOTAL)
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
