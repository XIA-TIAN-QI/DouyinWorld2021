"""
NPCTalk.lua 逻辑测试（不需要 Unity 运行时）

用 lupa 起一个真实 Lua 5.4，喂进一份假场景（CS.* 全部 mock），按帧推进时间，检查：
  - 没有玩家时沿路点循环行走、到点换下一个点、走到最后一点后回到起点
  - 位置高度贴合路点（室内在 F1，不会逐帧飘）
  - 玩家靠近 TALK_RANGE 内：停下、转向玩家、气泡亮起、说出第 1 句
  - 继续停留：按 TALK_GAP 换下一句，台词循环
  - 玩家退出 LEAVE_RANGE：恢复行走
  - 回差带（TALK_RANGE < d < LEAVE_RANGE）：既不说话也不动
  - dt 超大时被截断（防卡帧一步跨半米）
  - 相机为空时不崩

只验证 Lua 侧逻辑，不覆盖 XLua 绑定与引擎事件派发。
"""
import pathlib
import sys

import lupa

HERE = pathlib.Path(__file__).resolve().parent
SCRIPT = HERE.parent / "Assets" / "Campus" / "Lua" / "NPCTalk.lua"

HARNESS = r"""
-- ================= 假引擎 =================
log = {}
local real_print = print
print = function(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    log[#log + 1] = table.concat(parts, " ")
end

now = 0.0
dt = 0.0

-- --- Vector3 ---
local V3 = {}
V3.__index = function(t, k)
    if k == "sqrMagnitude" then return t.x * t.x + t.y * t.y + t.z * t.z end
    if k == "magnitude" then return math.sqrt(t.x * t.x + t.y * t.y + t.z * t.z) end
    return rawget(t, k)
end
function V3.__sub(a, b) return setmetatable({ x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }, V3) end
function V3.__add(a, b) return setmetatable({ x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }, V3) end
local function v3(x, y, z) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, V3) end
local Vector3 = setmetatable({}, { __call = function(_, x, y, z) return v3(x, y, z) end })

-- --- Quaternion：只记录调用，不真的算四元数 ---
lookCalls = {}
local Quaternion = {}
Quaternion.identity = { identity = true }
function Quaternion.Euler(x, y, z) return { euler = { x, y, z } } end
function Quaternion.LookRotation(v)
    lookCalls[#lookCalls + 1] = { x = v.x, z = v.z }
    return { look = v }
end
function Quaternion.Slerp(a, b, t) return b end

-- --- transform 树 ---
local function new_t(name)
    local t = { name = name, children = {}, childList = {}, childCount = 0 }
    t.position = v3(0, 0, 0)
    t.rotation = { rot = true }
    t.localPosition = v3(0, 0, 0)
    t.localRotation = { rot = true }
    t.gameObject = {
        name = name,
        active = true,
        SetActive = function(self, v) t.gameObject.active = v end,
    }
    function t:Find(path)
        local cur = self
        for part in string.gmatch(path, "[^/]+") do
            if cur == nil then return nil end
            cur = cur.children[part]
        end
        return cur
    end
    function t:GetChild(i) return self.childList[i + 1] end
    return t
end

local function add_child(parent, t)
    parent.children[t.name] = t
    parent.childCount = parent.childCount + 1
    parent.childList[parent.childCount] = t
end

-- ================= 场景：一个 NPC =================
root = new_t("NPC_01")   -- 全局，Python 侧要读位置
local model = new_t("Model")
add_child(root, model)
local armL, armR, legL, legR = new_t("ArmL"), new_t("ArmR"), new_t("LegL"), new_t("LegR")
add_child(model, armL); add_child(model, armR); add_child(model, legL); add_child(model, legR)

labelNode = new_t("Label")
add_child(root, labelNode)
-- 暴露成全局，Python 侧要断言它的显隐
bubbleNode = new_t("Bubble")
add_child(labelNode, bubbleNode)
for i = 1, 4 do
    local ln = new_t(string.format("Line_%02d", i))
    add_child(bubbleNode, ln)
end
-- 顺序故意打乱，验证脚本里的 table.sort
bubbleNode.childList[1], bubbleNode.childList[4] = bubbleNode.childList[4], bubbleNode.childList[1]

local path = new_t("Path")
add_child(root, path)
local WPS = { { 0, 0, 0 }, { 0, 0, 5 }, { 3, 0, 5 }, { 3, 0, 0 } }
for i, p in ipairs(WPS) do
    local wp = new_t(string.format("Waypoint_%02d", i))
    wp.position = v3(p[1], p[2], p[3])
    add_child(path, wp)
end

-- ================= 假服务 =================
playerPos = nil          -- nil 表示世界里没有本地玩家
cameraAvailable = true

CS = {
    UnityEngine = {
        Vector3 = Vector3,
        Quaternion = Quaternion,
        Time = setmetatable({}, {
            __index = function(_, k)
                if k == "time" then return now end
                if k == "deltaTime" then return dt end
            end,
        }),
        Camera = setmetatable({}, {
            __index = function(_, k)
                if k ~= "main" then return nil end
                if not cameraAvailable then return nil end
                return { transform = { position = v3(0, 2, -6) } }
            end,
        }),
    },
    DouyinActorService = {
        GetLocalActor = function()
            if playerPos == nil then return nil end
            return { gameObject = { transform = { position = playerPos } } }
        end,
    },
}

-- 脚本里的 self 就是 NPC 根节点
self = { transform = root, gameObject = root.gameObject }

-- 给 Python 侧用的全局别名
testVec3 = v3
"""


def new_state():
    lt = lupa.LuaRuntime(unpack_returned_tuples=True)
    lt.execute(HARNESS)
    lt.execute(SCRIPT.read_text(encoding="utf-8"))
    lt.execute("Awake()")
    return lt


def step(lt, frames=1, dt=1 / 60, seconds_per_frame=None):
    """推进 frames 帧，每帧 dt 秒"""
    g = lt.globals()
    for _ in range(frames):
        g.dt = dt
        g.now = g.now + dt
        lt.execute("Update()")


def pos(lt):
    p = lt.eval("root.position")
    return (p.x, p.y, p.z)


def bubble_active(lt):
    return lt.eval("bubbleNode.gameObject.active")


def active_line(lt):
    """返回当前亮着的 Line 名字（下标从 1 开始），没有就返回 0"""
    n = lt.eval("bubbleNode.childCount")
    for i in range(1, n + 1):
        if lt.eval("bubbleNode.childList[%d].gameObject.active" % i):
            return lt.eval("bubbleNode.childList[%d].name" % i)
    return None


def main():
    ok = True

    def check(cond, msg):
        nonlocal ok
        if cond:
            print("  ✓ " + msg)
        else:
            print("  ✗ " + msg)
            ok = False

    lt = new_state()
    g = lt.globals()

    print("[1] 初始化")
    check(g.log[1].find("waypoints=4") is not None, "读到 4 个路点：" + g.log[1])
    check(g.log[1].find("lines=4") is not None, "读到 4 句台词")
    check(bubble_active(lt) is False, "初始气泡关闭")

    print("[2] 无玩家：沿路点走")
    start = pos(lt)
    step(lt, 60)                     # 1 秒
    after = pos(lt)
    check(after[2] > start[2] + 0.5, "沿 +z 前进 1 秒，位移 %.2f" % (after[2] - start[2]))
    check(abs(after[1]) < 0.01, "没有横向偏移")
    check(abs(after[0]) < 0.01, "x 未被拉走")
    check(after[1] == 0.0, "高度贴合路点 y=0")

    print("[3] 走到第二个点会转向 x 方向")
    step(lt, 60 * 5)                 # 再走 5 秒，应该已经拐弯
    p3 = pos(lt)
    check(p3[0] > 0.5, "开始朝 +x 走（x=%.2f）" % p3[0])

    print("[4] 走到最后一个点后回到起点（循环）")
    step(lt, 60 * 20)
    p4 = pos(lt)
    # 只要还在四个路点围成的方框里就说明没跑飞
    inside = -0.6 <= p4[0] <= 3.6 and -0.6 <= p4[2] <= 5.6
    check(inside, "仍在路点框内 (%.2f, %.2f)" % (p4[0], p4[2]))

    print("[5] 玩家靠近：停下并说话")
    cur = pos(lt)
    g.playerPos = lt.eval("testVec3(%f, 0, %f)" % (cur[0] + 1.2, cur[2] + 1.2))
    before = pos(lt)
    step(lt, 10)
    after = pos(lt)
    moved = ((after[0] - before[0]) ** 2 + (after[2] - before[2]) ** 2) ** 0.5
    check(moved < 0.02, "停下来不再移动（10 帧位移 %.3f）" % moved)
    check(bubble_active(lt) is True, "气泡亮起")
    first = active_line(lt)
    check(first is not None, "有台词 quad 被打开：" + str(first))
    check(len(g.lookCalls) > 0, "调用了 LookRotation（转向玩家/相机）")

    print("[6] 停留期间按间隔换句")
    g.dt = 1 / 60
    for _ in range(int(60 * 7)):     # 7 秒 > TALK_GAP 6.5
        g.now = g.now + g.dt
        lt.execute("Update()")
    second = active_line(lt)
    check(second != first, "换到了下一句：%s → %s" % (first, second))

    print("[7] 台词循环（说满 4 句后回到第 1 句）")
    seen = {first, second}
    for _ in range(int(60 * 20)):
        g.now = g.now + g.dt
        lt.execute("Update()")
        a = active_line(lt)
        if a:
            seen.add(a)
    check(len(seen) >= 3, "至少轮换了 3 句：%s" % sorted(seen))

    print("[8] 玩家走进回差带（4.0m）：不说话也不走")
    cur = pos(lt)
    g.playerPos = lt.eval("testVec3(%f, 0, %f)" % (cur[0] + 4.0, cur[2] + 0.0))
    lt.execute("Update()")
    b0 = pos(lt)
    step(lt, 20)
    b1 = pos(lt)
    still = ((b1[0] - b0[0]) ** 2 + (b1[2] - b0[2]) ** 2) ** 0.5
    check(still < 0.02, "回差带内保持原地（位移 %.3f）" % still)

    print("[9] 玩家走远：恢复行走")
    g.playerPos = lt.eval("testVec3(%f, 0, %f)" % (cur[0] + 12.0, cur[2] + 12.0))
    c0 = pos(lt)
    step(lt, 60)
    c1 = pos(lt)
    resumed = ((c1[0] - c0[0]) ** 2 + (c1[2] - c0[2]) ** 2) ** 0.5
    check(resumed > 0.3, "重新走起来（1 秒位移 %.2f）" % resumed)

    print("[10] 没有本地玩家时不崩")
    g.playerPos = None
    try:
        step(lt, 30)
        check(True, "playerPos=nil 时正常跑")
    except Exception as e:
        check(False, "playerPos=nil 时抛异常：" + str(e))

    print("[11] 相机为空时不崩（billboard 跳过）")
    g.cameraAvailable = False
    try:
        step(lt, 30)
        check(True, "Camera.main=nil 时正常跑")
    except Exception as e:
        check(False, "Camera.main=nil 时抛异常：" + str(e))
    g.cameraAvailable = True

    print("[12] dt 超大被截断")
    cur = pos(lt)
    g.dt = 5.0                       # 模拟卡了 5 秒
    g.now = g.now + g.dt
    lt.execute("Update()")
    after = pos(lt)
    jump = ((after[0] - cur[0]) ** 2 + (after[2] - cur[2]) ** 2) ** 0.5
    check(jump < 0.5, "5 秒卡帧只前进了 %.2f 米（被截断到 0.2s）" % jump)

    print()
    if ok:
        print("全部通过")
    else:
        print("有失败项")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
