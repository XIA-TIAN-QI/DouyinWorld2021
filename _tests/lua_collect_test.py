"""
CampusCollect.lua 逻辑测试（不需要 Unity 运行时）

用 lupa 起一个真实 Lua 5.4 解释器，喂进一份假场景（CS.* 全部 mock），
然后按真实事件顺序模拟 8 次拾取交付，检查：
  槽位点亮 / 徽章落位 / 碰撞与脚本关闭 / 奖励点亮 / 去重 / 非本机玩家过滤

只验证 Lua 侧逻辑，不覆盖 XLua 绑定与引擎事件派发 —— 那两层靠
SDK 示例脚本的写法对齐 + 场景诊断（_campus_report.txt）。
"""
import pathlib
import sys

import lupa

HERE = pathlib.Path(__file__).resolve().parent
SCRIPT = HERE.parent / "Assets" / "Campus" / "Lua" / "CampusCollect.lua"

HARNESS = r"""
-- ================= 假场景 =================
log = {}
scene = { glows = {}, slots = {}, items = {} }

local real_print = print
print = function(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    log[#log + 1] = table.concat(parts, " ")
end

local function new_transform(name)
    local t = { name = name, childCount = 0, childList = {}, children = {} }
    t.position = "pos_of_" .. name
    t.rotation = "rot_of_" .. name
    t.active = true
    t.gameObject = {
        name = name,
        SetActive = function(self, v) t.active = v end,
    }
    function t:Find(n) return self.children[n] end
    function t:GetChild(i) return self.childList[i + 1] end
    return t
end

-- 陈列架 8 个槽位 + Glow
local shelfT = new_transform("CollectShelf")
for i = 1, 8 do
    local name = string.format("Slot_%02d", i)
    local slotT = new_transform(name)
    local glowT = new_transform("Glow")
    glowT.gameObject:SetActive(false)
    slotT.children["Glow"] = glowT
    shelfT.children[name] = slotT
    scene.slots[i] = slotT
    scene.glows[i] = glowT
end
shelfGo = { name = "CollectShelf", transform = shelfT }

-- 广场奖励：根节点激活、子物体全隐藏
local rewardT = new_transform("Plaza_Reward")
local rewardKids = {}
for i = 1, 8 do
    local kid = new_transform("Reward_" .. i)
    kid.gameObject:SetActive(false)
    rewardKids[i] = kid
    rewardT.childList[i] = kid
end
rewardT.childCount = #rewardKids
rewardGo = { name = "Plaza_Reward", transform = rewardT }
scene.reward = rewardT
scene.rewardKids = rewardKids

-- 拾取物
local function new_item(name)
    local t = new_transform(name)
    local rb = { isKinematic = false, useGravity = true }
    local script = { enabled = true }
    -- XLua 里 C# 数组是 0 基代理，这里用元表模拟同样的下标语义
    local raw = { { enabled = true }, { enabled = true } }
    local cols = setmetatable({ Length = #raw }, {
        __index = function(_, k)
            if type(k) == "number" then return raw[k + 1] end
            return nil
        end,
    })
    local go = { name = name, transform = t }
    function go:GetComponent(ty)
        if ty == CS.UnityEngine.Rigidbody then return rb end
        if ty == CS.DouyinScript then return script end
        return nil
    end
    function go:GetComponentsInChildren(ty) return cols end
    return { go = go, rb = rb, script = script, cols = cols }
end

for i = 1, 8 do
    scene.items[i] = new_item(string.format("Collect_%02d", i))
end

-- CS / typeof / 事件
-- Time 用递增帧号模拟：每次读 frameCount 都换一个新值，
-- 免得 CampusCollect 的帧去重把测试里的多次 Update() 吃掉
_frameNo = 0
local seqTime = setmetatable({}, {
    __index = function(_, k)
        if k == "frameCount" then
            _frameNo = _frameNo + 1
            return _frameNo
        end
        if k == "time" then return _frameNo * 0.1 end
        return nil
    end,
})

CS = {
    UnityEngine = {
        Time = seqTime,
        GameObject = {
            Find = function(n)
                if n == "CollectShelf" then return shelfGo end
                if n == "Plaza_Reward" then return rewardGo end
                -- 真实场景里 Collect_xx 是激活的、Find 得到的；恢复存档要靠它摆回架上
                local idx = string.match(n, "^Collect_(%d+)$")
                if idx ~= nil and scene.items[tonumber(idx)] ~= nil then
                    return scene.items[tonumber(idx)].go
                end
                return nil
            end,
        },
        Rigidbody = "Rigidbody",
        Collider = "Collider",
    },
    DouyinScript = "DouyinScript",
    HandType = { All = "All", Left = "Left", Right = "Right" },
    DouyinUtility = {
        Toast = function(msg) log[#log + 1] = "TOAST:" .. msg end,
    },
}

typeof = function(x) return x end

actor = { isLocal = true, held = nil }
function actor:GetPickupInHand(handType) return self.held end
function actor:Drop(item) self.dropped = item; self.held = nil end

local player = { GetActor = function(self) return actor end }
player.isLocal = true
scene.player = player
"""

TESTS = r"""
-- ================= 断言 =================
failures = {}
local function check(cond, msg)
    if not cond then failures[#failures + 1] = msg end
end

local countLog = function(pat)
    local n = 0
    for _, line in ipairs(log) do
        if string.find(line, pat, 1, true) then n = n + 1 end
    end
    return n
end

Awake()
check(#log == 1 and string.find(log[1], "ready, total=8", 1, true) ~= nil, "Awake 未打印 ready")

-- 任务 API：注册与初始状态
local q = _G["CampusQuest"]
check(q ~= nil, "CampusQuest 未注册")
if q ~= nil then
    check(q:IsAccepted() == false, "初始不该已接取")
    check(q:Count() == 0, "初始计数不是 0")
    check(q:IsComplete() == false, "初始不该完成")
    check(q:Stage() == "idle", "初始阶段不是 idle")

    -- 主动接取：老陈发任务走这条
    q:Accept()
    check(q:IsAccepted() == true, "Accept() 没生效")
    check(q:Stage() == "collecting", "Accept() 后阶段不是 collecting")
    check(countLog("TOAST:任务") == 1, "接取提示没弹")
end

-- 空手进入：什么都不该发生
actor.held = nil
OnPlayerTriggerEnter(scene.player)
check(countLog("已入柜") == 0, "空手进入也入柜了")

-- 非本机玩家进入：忽略
actor.isLocal = false
actor.held = scene.items[3].go
OnPlayerTriggerEnter(scene.player)
check(countLog("已入柜") == 0, "非本机玩家的徽章被收了")
actor.isLocal = true
actor.held = nil

-- 前 7 枚走玩家触发器
for i = 1, 7 do
    actor.held = scene.items[i].go
    OnPlayerTriggerEnter(scene.player)
end
check(countLog("已入柜") == 7, "前 7 枚入柜数量不符：" .. countLog("已入柜"))
check(scene.glows[7].active == true, "第 7 格没点亮")
check(scene.glows[8].active == false, "第 8 格提前亮了")
check(scene.items[7].go.transform.position == scene.slots[7].position, "第 7 枚没落到槽位")
check(scene.items[7].rb.isKinematic == true, "第 7 枚没冻结")
check(scene.items[7].cols[0].enabled == false, "第 7 枚碰撞体没关")
check(scene.items[7].script.enabled == false, "第 7 枚脚本没关")
check(scene.rewardKids[1].active == false, "没集齐就把奖励点亮了")

-- 任务进度：7 枚时仍在进行中，线索可用
if q ~= nil then
    check(q:Count() == 7, "计数不是 7")
    check(q:Has(7) == true and q:Has(8) == false, "Has() 状态不对")
    check(q:Stage() == "collecting", "阶段不是 collecting")
    check(q:HintLine("NPC_04") == 4, "进行中没给线索")
end

-- 重复交付：同一枚再进一次，不应计数
actor.held = scene.items[3].go
OnPlayerTriggerEnter(scene.player)
check(countLog("已入柜") == 7, "重复交付被计数了")

-- 第 8 枚走角色侧事件（备用通道）
actor.held = scene.items[8].go
OnActorTriggerEnter(actor)
check(countLog("已入柜") == 8, "第 8 枚没入柜")

-- 集齐
local lit = 0
for i = 1, 8 do if scene.rewardKids[i].active then lit = lit + 1 end end
check(lit == 8, "奖励子物体点亮 " .. lit .. "/8")
check(countLog("全部集齐") == 1, "集齐日志没打印")
check(countLog("TOAST:八枚校徽集齐") == 1, "集齐提示没弹")

-- 任务完成：阶段切换、线索关闭
if q ~= nil then
    check(q:IsComplete() == true, "没有标记完成")
    check(q:Stage() == "done", "阶段不是 done")
    check(q:HintLine("NPC_04") == nil, "完成后还在给线索")
end

-- 全部 8 格都亮
local glowOn = 0
for i = 1, 8 do if scene.glows[i].active then glowOn = glowOn + 1 end end
check(glowOn == 8, "亮起的格子 " .. glowOn .. "/8")

-- 集齐后再进：不报错、不重复
actor.held = scene.items[1].go
OnPlayerTriggerEnter(scene.player)
check(countLog("已入柜") == 8, "集齐后重复进入产生了额外计数")

-- 找不到奖励物体时的兜底（不能崩）

-- ================= 存档恢复：取并集，不覆盖 =================
_G["CampusSave"] = nil
for i = 1, 8 do
    scene.items[i].script.enabled = true
    scene.items[i].rb.isKinematic = false
    scene.items[i].cols[0].enabled = true
    scene.glows[i].active = false
    scene.rewardKids[i].active = false
end
actor.held = nil
actor.isLocal = true

Awake()
q = _G["CampusQuest"]

-- 运行时先捡第 5 枚：模拟"存档还没到，玩家已经动手了"
actor.held = scene.items[5].go
OnPlayerTriggerEnter(scene.player)
check(q:Count() == 1, "运行时先捡一枚，计数应为 1，实际 " .. q:Count())

local beforeDone = countLog("已入柜")   -- 以此为基准：恢复不该再走一遍入柜流程

-- 喂存档：1 和 5 都已入柜。5 是重复的，不能重复计数
saveMock = { emblems = "10001000", quest = 1, flushes = 0 }
function saveMock.Get(key, def)
    local v = saveMock[key]
    if v == nil then return def end
    return v
end
function saveMock.Set(key, v) saveMock[key] = v end
function saveMock.Flush(force) saveMock.flushes = saveMock.flushes + 1 end
function saveMock.OnReady(fn) fn() end
function saveMock.Ready() return true end
_G["CampusSave"] = saveMock

Update()   -- 补挂：Awake 时 CampusSave 还是 nil，靠帧驱动补上

check(q:Count() == 2, "合并后应为 2（补 1 枚、5 已存在不重复），实际 " .. q:Count())
check(q:Has(1) == true and q:Has(5) == true and q:Has(2) == false, "恢复的位图不对")
check(q:IsAccepted() == true and q:Stage() == "collecting", "任务状态没从存档恢复")
check(scene.glows[1].active == true, "恢复的第 1 格没点亮")
check(scene.glows[2].active == false, "没恢复的第 2 格却亮了")
check(scene.items[1].script.enabled == false, "恢复的徽章没摆上架（拾取脚本还开着）")
check(scene.items[1].go.transform.position == scene.slots[1].position, "恢复的徽章没落到槽位")
check(countLog("已入柜") == beforeDone, "恢复不该走入柜流程（会重复计数 / 弹 Toast）")
check(countLog("存档恢复") == 1, "没打印恢复日志")

-- 存档说集齐 → 重进世界要直接把广场地标点亮
_G["CampusSave"] = nil
Awake()
q = _G["CampusQuest"]
saveMock.emblems = "11111111"
saveMock.quest = 1
_G["CampusSave"] = saveMock
Update()

check(q:Count() == 8, "满档存档恢复后应为 8，实际 " .. q:Count())
check(q:IsComplete() == true and q:Stage() == "done", "满档存档没标记完成")
local lit2 = 0
for i = 1, 8 do if scene.rewardKids[i].active then lit2 = lit2 + 1 end end
check(lit2 == 8, "满档存档没点亮广场地标（" .. lit2 .. "/8）")

-- 入柜要把新进度写回存档
_G["CampusSave"] = nil
for i = 1, 8 do
    scene.items[i].script.enabled = true
    scene.glows[i].active = false
    scene.rewardKids[i].active = false
end
Awake()
q = _G["CampusQuest"]
saveMock.emblems = "00000000"
saveMock.quest = 0
saveMock.flushes = 0
_G["CampusSave"] = saveMock
Update()

actor.held = scene.items[2].go
local beforeTip = countLog("老陈让你把八枚带回门厅陈列架")
OnPlayerTriggerEnter(scene.player)
check(saveMock.emblems == "01000000", "入柜后位图没写回：" .. tostring(saveMock.emblems))
check(saveMock.quest == 1, "入柜后任务位没写回")
check(saveMock.flushes >= 1, "入柜后没有触发 Flush")
-- 这一段是"没接任务就先捡"的路径：必须补提示，否则玩家不知道自己在收集什么
check(countLog("老陈让你把八枚带回门厅陈列架") == beforeTip + 1,
    "未接任务时捡第一枚没有补提示")

-- 存档到达前就捡了一枚：恢复时必须并集回写，否则那枚永久丢失
_G["CampusSave"] = nil
for i = 1, 8 do
    scene.items[i].script.enabled = true
    scene.glows[i].active = false
    scene.rewardKids[i].active = false
end

-- 模拟"存档层已存在但还没就绪"。
-- 注意要分两层：emblems = 服务端值，pendingVals = 内存里待写的值。
-- 真实 CampusSave 在 ready=false 时 Set 只改内存、Flush 直接返回，不会碰服务端。
lazySave = { emblems = "00000000", quest = 0, flushes = 0, pendingVals = {} }
function lazySave.Get(key, def)
    if not lazySave.isReady then return def end
    local v = lazySave[key]
    if v == nil then return def end
    return v
end
function lazySave.Set(key, v) lazySave.pendingVals[key] = v end
function lazySave.Flush(force)
    if not lazySave.isReady then return end
    for k, v in pairs(lazySave.pendingVals) do lazySave[k] = v end
    lazySave.pendingVals = {}
    lazySave.flushes = lazySave.flushes + 1
end
function lazySave.Ready() return lazySave.isReady == true end
function lazySave.OnReady(fn) lazySave.pending = fn end
_G["CampusSave"] = lazySave

Awake()
q = _G["CampusQuest"]

-- 存档还没到，玩家已经捡了第 4 枚
actor.held = scene.items[4].go
OnPlayerTriggerEnter(scene.player)
check(q:Count() == 1, "存档到达前先捡一枚")
check(lazySave.emblems == "00000000", "未就绪时不落盘（没污染服务端）")

-- 存档到达：里面只有第 1 枚
lazySave.emblems = "10000000"
lazySave.quest = 1
lazySave.isReady = true
lazySave.pending()      -- 触发 Restore，内部会补写一次

check(q:Count() == 2, "合并后应为 2 枚，实际 " .. q:Count())
check(lazySave.emblems == "10010000",
    "恢复后必须回写并集，否则第 4 枚永久丢失：" .. tostring(lazySave.emblems))

result = { failures = failures, log = log }
"""

def main() -> int:
    if not SCRIPT.exists():
        print(f"找不到脚本: {SCRIPT}")
        return 2

    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    src = HARNESS + "\n" + SCRIPT.read_text(encoding="utf-8") + "\n" + TESTS
    lua.execute(src)

    result = lua.globals().result
    failures = list(result["failures"].values())
    log = list(result["log"].values())

    print("---- 运行日志 ----")
    for line in log:
        print("  " + line)
    print("---- 结果 ----")
    if failures:
        for f in failures:
            print("  ✗ " + f)
        print(f"FAIL: {len(failures)} 项不符合预期")
        return 1

    print("  ✓ 8 枚全部入柜、槽位逐个点亮、奖励 8 个子物体点亮")
    print("  ✓ 空手进入 / 非本机玩家 / 重复交付 均被正确忽略")
    print("  ✓ 徽章冻结落位、碰撞体与拾取脚本关闭")
    return 0


if __name__ == "__main__":
    sys.exit(main())
