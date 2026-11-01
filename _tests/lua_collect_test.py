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
CS = {
    UnityEngine = {
        GameObject = {
            Find = function(n)
                if n == "CollectShelf" then return shelfGo end
                if n == "Plaza_Reward" then return rewardGo end
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
check(countLog("TOAST:校徽集齐") == 1, "集齐提示没弹")

-- 全部 8 格都亮
local glowOn = 0
for i = 1, 8 do if scene.glows[i].active then glowOn = glowOn + 1 end end
check(glowOn == 8, "亮起的格子 " .. glowOn .. "/8")

-- 集齐后再进：不报错、不重复
actor.held = scene.items[1].go
OnPlayerTriggerEnter(scene.player)
check(countLog("已入柜") == 8, "集齐后重复进入产生了额外计数")

-- 找不到奖励物体时的兜底（不能崩）
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
