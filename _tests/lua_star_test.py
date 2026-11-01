"""
CampusStar.lua（黄思诚）逻辑测试 —— 不需要 Unity 运行时。

用 lupa 起真实 Lua 5.4 + 假引擎，重点验证她的行为跟路人 NPC 不一样的地方：
  - 没人时站在待机点不动（不巡逻）
  - 玩家在 NOTICE(14m) 外：不理（防止远处一进来就冲过去）
  - 玩家进入 14m：主动迎上来，停在 1.9m，不贴脸
  - 停下后说话、按间隔换句、气泡到点收
  - 玩家在 3~14m 之间移动：她跟着走（这是"跟着你"的核心）
  - 玩家上楼（高度差 > 1m）：放弃，回原位（她没有寻路能力，硬追会贴墙）
  - 玩家跑到活动范围外：走到范围边界停下等，不会一路蹭墙
  - 玩家消失 / 走太远：回待机点
  - 卡帧 dt 截断

只验证 Lua 逻辑，不覆盖 XLua 绑定与引擎事件派发。
"""
import pathlib
import sys

import lupa

HERE = pathlib.Path(__file__).resolve().parent
SCRIPT = HERE.parent / "Assets" / "Campus" / "Lua" / "CampusStar.lua"

HARNESS = r"""
log = {}
print = function(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    log[#log + 1] = table.concat(parts, " ")
end

now = 0.0
dt = 0.0

-- 台词配音：voicePlays[name] = {clip, played}，Lua 的 ShowQuad 应该对显示的 quad Play 一次
voicePlays = {}
function typeof(t) return t end

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

lookCalls = 0
local Quaternion = {}
Quaternion.identity = { identity = true }
function Quaternion.Euler(x, y, z) return { euler = { x, y, z } } end
function Quaternion.LookRotation(v) lookCalls = lookCalls + 1; return { look = v } end
function Quaternion.Slerp(a, b, t) return b end

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
        -- 台词配音：只有 Line_x_xx 命名的 quad 带音源（和构建脚本一致），
        -- 其余节点（名牌/路点）GetComponent 返回 nil
        GetComponent = function(self, typ)
            if string.match(name, "^Line_%d+_%d+$") then
                local s = voicePlays[name]
                if s == nil then
                    s = { clip = "Voice/" .. name .. ".ogg", played = 0 }
                    function s:Play() s.played = s.played + 1 end
                    voicePlays[name] = s
                end
                return s
            end
            return nil
        end,
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

-- ================= 场景：NPC_08 黄思诚 =================
root = new_t("NPC_08")
root.position = v3(1.5, 0, -5.8)          -- StarHome
local model = new_t("Model")
add_child(root, model)
local armL, armR, legL, legR = new_t("ArmL"), new_t("ArmR"), new_t("LegL"), new_t("LegR")
add_child(model, armL); add_child(model, armR); add_child(model, legL); add_child(model, legR)

labelNode = new_t("Label")
add_child(root, labelNode)
bubbleNode = new_t("Bubble")
add_child(labelNode, bubbleNode)
-- 台词 quad：四档，命名 Line_<档>_<序号>（和构建脚本一致）
-- 每档都按倒序插入，验证 Lua 会自己按名字重排，而不是依赖子物体顺序
local QUAD_COUNTS = { 8, 5, 5, 4 }   -- 与 NpcLines.txt 实际一致（典礼台词是第 4 档第 4 句）
for tier = 1, 4 do
    for i = QUAD_COUNTS[tier], 1, -1 do
        add_child(bubbleNode, new_t(string.format("Line_%d_%02d", tier, i)))
    end
end

local path = new_t("Path")
add_child(root, path)
local home = new_t("Waypoint_01")
home.position = v3(1.5, 0, -5.8)
add_child(path, home)

playerPos = nil
cameraAvailable = true
toastLog = {}

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
                return { transform = { position = v3(0, 2, -30) } }
            end,
        }),
    },
    DouyinUtility = {
        Toast = function(s) toastLog[#toastLog + 1] = s end,
    },
    DouyinActorService = {
        GetLocalActor = function()
            if playerPos == nil then return nil end
            return { gameObject = { transform = { position = playerPos } } }
        end,
    },
}

self = { transform = root, gameObject = root.gameObject }
testVec3 = v3
"""


def new_state():
    lt = lupa.LuaRuntime(unpack_returned_tuples=True)
    lt.execute(HARNESS)
    lt.execute(SCRIPT.read_text(encoding="utf-8"))
    lt.execute("Awake()")
    return lt


def step(lt, frames=1, dt=1 / 60):
    g = lt.globals()
    for _ in range(frames):
        g.dt = dt
        g.now = g.now + dt
        lt.execute("Update()")


def pos(lt):
    p = lt.eval("root.position")
    return (p.x, p.y, p.z)


def player_at(lt, x, y, z):
    lt.globals().playerPos = lt.eval("testVec3(%f, %f, %f)" % (x, y, z))


def bubble_active(lt):
    return lt.eval("bubbleNode.gameObject.active")


def active_line(lt):
    n = lt.eval("bubbleNode.childCount")
    for i in range(1, n + 1):
        if lt.eval("bubbleNode.childList[%d].gameObject.active" % i):
            return lt.eval("bubbleNode.childList[%d].name" % i)
    return None


def dist_xz(a, b):
    return ((a[0] - b[0]) ** 2 + (a[2] - b[2]) ** 2) ** 0.5


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
    check(g.log[1].find("lines=22") != -1, "读到 22 句台词（8+5+5+4）：" + g.log[1])
    check(g.log[1].find("home") != -1 and g.log[1].find("home=nil") == -1, "读到待机点")
    check(bubble_active(lt) is False, "初始气泡关闭")

    print("[2] 没有玩家：站在待机点不动")
    home = pos(lt)
    step(lt, 120)
    p = pos(lt)
    check(dist_xz(p, home) < 0.01, "原地不动（位移 %.3f）" % dist_xz(p, home))

    print("[3] 玩家在 NOTICE 外（18m）：不理")
    player_at(lt, 1.5, 0, 12.2)          # 距她 18m
    step(lt, 60)
    p = pos(lt)
    check(dist_xz(p, home) < 0.05, "没有冲过去（位移 %.3f）" % dist_xz(p, home))

    print("[4] 玩家进入 10m：主动迎上来")
    player_at(lt, 1.5, 0, 4.2)
    step(lt, 60 * 5)
    p = pos(lt)
    d = dist_xz(p, (1.5, 0, 4.2))
    check(p[2] > home[2] + 2.0, "朝玩家方向移动了 %.1fm" % (p[2] - home[2]))
    check(1.5 < d < 2.6, "停在 1.9m 左右，没有贴脸（实际 %.2fm）" % d)

    print("[5] 停下后开口")
    check(bubble_active(lt) is True, "气泡亮起")
    first = active_line(lt)
    check(first is not None, "有台词被打开：" + str(first))

    print("[6] 按间隔换句（她话密，4.6s 一句）")
    g.dt = 1 / 60
    for _ in range(int(60 * 5)):
        g.now = g.now + g.dt
        lt.execute("Update()")
    second = active_line(lt)
    check(second != first, "换到了下一句：%s → %s" % (first, second))

    print("[7] 气泡到点会收（4.5s），下一句（4.6s）才补上")
    last = bubble_active(lt)
    t0 = g.now
    off_at = None
    for _ in range(int(60 * 6)):
        g.now = g.now + g.dt
        lt.execute("Update()")
        cur = bubble_active(lt)
        if last and not cur:
            off_at = g.now - t0
            break
        last = cur
    check(off_at is not None and off_at < 5.0,
          "气泡在 %.2fs 时收掉" % (off_at if off_at else -1))

    print("[8] 玩家走开 11m：她跟上来（不是原地等）")
    p0 = pos(lt)
    player_at(lt, 1.5, 0, p0[2] + 11.0)
    step(lt, 60 * 6)
    p1 = pos(lt)
    check(dist_xz(p1, p0) > 3.0, "跟了 %.1fm" % dist_xz(p1, p0))
    d = dist_xz(p1, (1.5, 0, p0[2] + 11.0))
    check(d < 4.0, "追到玩家附近（还差 %.2fm）" % d)

    print("[9] 玩家上楼（y=5.5）：放弃并回原位")
    cur = pos(lt)
    player_at(lt, cur[0], 5.5, cur[2] + 1.0)
    step(lt, 60 * 8)
    p = pos(lt)
    check(abs(p[1]) < 0.01, "高度没被拉上去（y=%.2f）" % p[1])
    check(dist_xz(p, home) < 1.2, "回到待机点附近（差 %.2fm）" % dist_xz(p, home))

    print("[10] 玩家跑到活动范围外（x=20）：走到边界就停")
    player_at(lt, 6.0, 0, -5.8)          # 先靠近，触发 engaged
    step(lt, 60)
    player_at(lt, 20.0, 0, -5.8)         # 再横移到框外
    step(lt, 60 * 8)
    p = pos(lt)
    check(p[0] <= 13.15, "没有越过活动边界（x=%.2f）" % p[0])

    print("[11] 玩家走太远（>22m）：不追")
    player_at(lt, 1.5, 0, 30.0)
    step(lt, 60 * 8)
    p = pos(lt)
    check(dist_xz(p, home) < 1.5, "已放弃并回到待机点（差 %.2fm）" % dist_xz(p, home))

    print("[12] 没有本地玩家 / 没有相机都不崩")
    g.playerPos = None
    try:
        step(lt, 30)
        check(True, "playerPos=nil 正常跑")
    except Exception as e:
        check(False, "playerPos=nil 抛异常：" + str(e))
    g.cameraAvailable = False
    try:
        step(lt, 30)
        check(True, "Camera.main=nil 正常跑")
    except Exception as e:
        check(False, "Camera.main=nil 抛异常：" + str(e))
    g.cameraAvailable = True

    print("[13] 卡帧 dt 截断")
    player_at(lt, 1.5, 0, 5.0)
    step(lt, 60)
    cur = pos(lt)
    g.dt = 5.0
    g.now = g.now + g.dt
    lt.execute("Update()")
    after = pos(lt)
    jump = dist_xz(after, cur)
    check(jump < 0.6, "卡 5 秒只走 %.2fm（截断到 0.2s）" % jump)

    print("[14] 好感度分档：陪着待着会升档，满档触发收尾")
    lt2 = new_state()
    player_at(lt2, 1.5, 0, -3.8)          # 距待机点 2m，落在 TALK_RANGE 内
    step(lt2, 60 * 20)
    l20 = active_line(lt2)
    check(l20 is not None and l20.startswith("Line_2"), "20s 后升到第 2 档：" + str(l20))
    step(lt2, 60 * 20)                     # 累计 40s
    l40 = active_line(lt2)
    t40 = int(l40.split("_")[1]) if l40 else 0
    check(t40 >= 3, "40s 后到第 3 档：" + str(l40))
    step(lt2, 60 * 35)                     # 累计 75s
    l75 = active_line(lt2)
    check(l75 is not None and l75.startswith("Line_4"), "75s 后到满档：" + str(l75))
    toasts = lt2.eval("#toastLog")
    check(toasts > 0, "升档/满档有 Toast 提示（%d 条）" % toasts)
    p = pos(lt2)
    d = dist_xz(p, (1.5, 0, -3.8))
    check(d < 1.7, "满档后靠得更近（%.2fm）" % d)

    print("[15] 存档恢复：好感度按档回归，且不重复提示")
    # 存档层 mock：OnReady 立即回放，等价于"读档比 Awake 晚，但在第一帧就到了"
    SAVE_MOCK = """
saveMock = { affinity = %d, flushes = 0 }
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
"""

    lt3 = new_state()
    lt3.execute(SAVE_MOCK % 100)          # 100 > 门槛 80 → 第 3 档
    player_at(lt3, 1.5, 0, -3.8)
    step(lt3, 1)                          # 一帧内补挂存档并恢复
    check(lt3.eval("#toastLog") == 0, "恢复第 3 档不弹提示（重进世界不该再报一遍）")
    l3 = active_line(lt3)
    check(l3 is not None and l3.startswith("Line_3"), "恢复后直接说第 3 档：" + str(l3))
    check(lt3.eval("saveMock.affinity") >= 100, "内存值同步进了存档层")

    lt4 = new_state()
    lt4.execute(SAVE_MOCK % 200)          # 满档
    player_at(lt4, 1.5, 0, -3.8)
    step(lt4, 60 * 6)
    check(lt4.eval("#toastLog") == 0, "满档存档恢复不重复弹提示")
    l4 = active_line(lt4)
    check(l4 is not None and l4.startswith("Line_4"), "恢复满档直接说第 4 档：" + str(l4))
    p = pos(lt4)
    d = dist_xz(p, (1.5, 0, -3.8))
    check(d < 1.7, "恢复满档后靠得更近（%.2fm）" % d)

    print("[16] 对外状态接口（结局系统要用）")
    check(lt4.eval("_G['CampusStar'] ~= nil"), "CampusStar 已注册到 _G")
    check(lt4.eval("_G['CampusStar'].IsMax()") is True, "满档后 IsMax() 为 true")
    check(lt4.eval("_G['CampusStar'].Tier()") == 4, "Tier() 返回 4")
    lt5 = new_state()
    check(lt5.eval("_G['CampusStar'].IsMax()") is False, "新会话初始不是满档")
    check(lt5.eval("_G['CampusStar'].Affinity()") == 0, "初始好感 0")

    print("[17] 台词配音：显示哪句就播哪句的音")
    lt6 = new_state()
    player_at(lt6, 2.5, 0, -5.0)     # 站到她身边，让她开口
    step(lt6, 60 * 2)
    name6 = active_line(lt6)
    check(name6 is not None, "有台词在显示：" + str(name6))
    if name6:
        lt6.globals()["qname"] = name6
        check(lt6.eval("voicePlays[qname] ~= nil and voicePlays[qname].played == 1"),
            "这句 quad 的配音正好放了一次")
        total = lt6.eval("(function() local n=0 for _,s in pairs(voicePlays) do n=n+s.played end return n end)()")
        check(total == 1, "一次只响一句（共 %d 声）" % total)
    # 走开让气泡收掉，再回来 —— 换句后新 quad 的音要响，旧的不重复响
    step(lt6, 30)
    step(lt6, 3)
    name6b = active_line(lt6)
    if name6b and name6b != name6:
        lt6.globals()["qname2"] = name6b
        check(lt6.eval("voicePlays[qname2] ~= nil and voicePlays[qname2].played == 1"),
            "换句后新 quad 的配音放了一次")
        total2 = lt6.eval("(function() local n=0 for _,s in pairs(voicePlays) do n=n+s.played end return n end)()")
        check(total2 == 2, "累计两声，没有叠着响（共 %d 声）" % total2)

    print()
    print("全部通过" if ok else "有失败项")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
