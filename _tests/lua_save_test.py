"""
CampusSave.lua 逻辑测试（不需要 Unity 运行时）

用 lupa 起一个真实 Lua 解释器，mock 掉 SDK 的 DouyinDataStoreManager
（同步回调，等价于引擎里的 DATASTORE() 立即返回）与玩家服务，检查：

  [1] 新玩家：读不到数据时走默认值，并建立一条记录
  [2] 老玩家：能解析自己写的格式，8 位校徽 / 任务位 / 好感度都对
  [3] scope 用的是 playerOpenID —— 多人世界不能共用一份存档
  [4] **加载失败时绝不写盘**（最关键：否则默认值会覆盖真实存档）
  [5] 写盘节流：4 秒内多次 Flush 只发一次 SetData
  [6] 内容没变化不重复写
  [7] 读档失败最多重试 3 次就放弃，不会一直打服务端
  [8] 畸形数据不崩，按新玩家处理
  [9] 短校徽串会右补 0
"""
import pathlib
import sys

import lupa

HERE = pathlib.Path(__file__).resolve().parent
SCRIPT = HERE.parent / "Assets" / "Campus" / "Lua" / "CampusSave.lua"

HARNESS = r"""
-- ================= 假引擎 =================
log = {}
local real_print = print
print = function(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    log[#log + 1] = table.concat(parts, " ")
end

CS = { UnityEngine = { Time = { time = 0, frameCount = 0, deltaTime = 0 } } }
CS.DouyinPlayerService = nil

-- 服务端："这里"就是 DataStore
storeValue = nil          -- nil 表示这个玩家还没有数据
failGet = false
failSet = false
getCalls = {}
setCalls = {}

manager = {}
function manager.GetData(store, scope, key, cb)
    getCalls[#getCalls + 1] = { store = store, scope = scope, key = key }
    if failGet then cb(false, "network error", nil); return end
    if storeValue == nil then cb(true, "New Data", {}); return end
    cb(true, "Success", storeValue)
end
function manager.SetData(store, scope, key, value, cb)
    setCalls[#setCalls + 1] = { store = store, scope = scope, key = key, value = value }
    if failSet then cb(false, "write error", nil); return end
    storeValue = value
    cb(true, "Success", value)
end
_G["DouyinDataStoreManager"] = manager

-- 玩家
player = { playerOpenID = "openid_abc" }
CS.DouyinPlayerService = { GetLocalPlayer = function() return player end }
DouyinPlayerService = CS.DouyinPlayerService

frameNo = 0
-- 推进一帧：时间前进 dt 秒
function Advance(dt)
    frameNo = frameNo + 1
    CS.UnityEngine.Time.time = CS.UnityEngine.Time.time + dt
    CS.UnityEngine.Time.frameCount = frameNo
    LateUpdate()
end

-- 不动时间只推进帧（测"无变化不写"）
function TickOnly()
    frameNo = frameNo + 1
    CS.UnityEngine.Time.frameCount = frameNo
    LateUpdate()
end
"""


def new_state():
    lt = lupa.LuaRuntime(unpack_returned_tuples=True)
    lt.execute(HARNESS)
    lt.execute(SCRIPT.read_text(encoding="utf-8"))
    lt.execute("Awake()")
    return lt


def call(lt, expr):
    return lt.eval(expr)


def count_get(lt):
    return call(lt, "#getCalls")


def count_set(lt):
    return call(lt, "#setCalls")


def last_set_value(lt):
    n = count_set(lt)
    if n == 0:
        return None
    return call(lt, "setCalls[%d].value" % n)


def main():
    ok_all = True

    def check(cond, msg):
        nonlocal ok_all
        if cond:
            print("  ok   " + msg)
        else:
            ok_all = False
            print("  FAIL " + msg)

    # ---------------------------------------------------------------- 1
    print("[1] 新玩家：无存档")
    lt = new_state()
    lt.execute("Advance(0.1)")
    check(call(lt, "CampusSave.Ready()") is True, "第一帧就完成读档")
    check(call(lt, "CampusSave.Get('emblems', 'x')") == "00000000", "校徽默认 8 个 0")
    check(call(lt, "CampusSave.Get('affinity', -1)") == 0, "好感度默认 0")
    check(count_get(lt) == 1, "只发了一次 GetData")
    # 下一帧才写（TryLoad 那一帧直接 return）
    lt.execute("Advance(0.1)")
    check(count_set(lt) == 1, "新玩家建立了一条初始记录")
    check(last_set_value(lt) == "v1;e=00000000;q=0;a=0", "初始串格式正确：" + str(last_set_value(lt)))

    # ---------------------------------------------------------------- 2
    print()
    print("[2] 老玩家：解析已有存档")
    lt = new_state()
    lt.execute("storeValue = 'v1;e=10110010;q=1;a=42'")
    lt.execute("Advance(0.1)")
    check(call(lt, "CampusSave.Get('emblems', '')") == "10110010", "校徽位图还原")
    check(call(lt, "CampusSave.Get('quest', 0)") == 1, "任务位还原")
    check(call(lt, "CampusSave.Get('affinity', 0)") == 42, "好感度还原")
    lt.execute("Advance(0.1)")
    check(count_set(lt) == 0, "刚读到的内容不重复写回")

    # ---------------------------------------------------------------- 3
    print()
    print("[3] scope 隔离")
    check(call(lt, "getCalls[1].scope") == "openid_abc", "scope 用的是 playerOpenID")
    check(call(lt, "getCalls[1].store") == "campus", "store 名固定为 campus")
    check(call(lt, "getCalls[1].key") == "save", "只用一个键装全部状态")

    # ---------------------------------------------------------------- 4
    print()
    print("[4] 读档失败时禁止写盘（数据安全）")
    lt = new_state()
    lt.execute("failGet = true")
    lt.execute("Advance(0.1)")
    check(call(lt, "CampusSave.Ready()") is False, "读不到就不算就绪")
    # 强行写：即使调用方 Flush(true) 也必须被挡住
    lt.execute("CampusSave.Set('emblems', '11111111')")
    lt.execute("CampusSave.Flush(true)")
    lt.execute("Advance(5.0)")
    check(count_set(lt) == 0, "未就绪时 SetData 一次都没发（不会覆盖服务端存档）")

    # ---------------------------------------------------------------- 5
    print()
    print("[5] 写盘节流")
    lt = new_state()
    lt.execute("storeValue = 'v1;e=00000000;q=0;a=0'")
    lt.execute("Advance(0.1)")          # t=0.1 读档
    lt.execute("CampusSave.Set('affinity', 10)")
    lt.execute("Advance(0.1)")          # t=0.2 第一次变化，此前从未写过 → 立刻落盘
    base = count_set(lt)
    check(base == 1, "第一次变化立刻落盘")
    lt.execute("CampusSave.Set('affinity', 20)")
    lt.execute("Advance(1.0)")          # t=1.2，距上次 1.0s
    lt.execute("CampusSave.Set('affinity', 30)")
    lt.execute("Advance(1.0)")          # t=2.2，距上次 2.0s
    check(count_set(lt) == base, "4 秒内连改两次都没落盘（被节流）")
    lt.execute("Advance(3.0)")          # t=5.2，距上次 5.0s
    check(count_set(lt) == base + 1, "超过间隔后落盘一次")
    check(last_set_value(lt) == "v1;e=00000000;q=0;a=30", "落盘的是最新值")

    # ---------------------------------------------------------------- 6
    print()
    print("[6] 内容没变不重复写")
    base = count_set(lt)
    lt.execute("Advance(10.0)")
    lt.execute("Advance(10.0)")
    check(count_set(lt) == base, "内容一致时定期写被跳过")

    # ---------------------------------------------------------------- 7
    print()
    print("[7] 读档重试上限")
    lt = new_state()
    lt.execute("failGet = true")
    lt.execute("Advance(0.1)")
    for _ in range(6):
        lt.execute("Advance(20.0)")
    check(count_get(lt) == 3, "失败 3 次后不再打服务端，实际次数=" + str(count_get(lt)))

    # ---------------------------------------------------------------- 8
    print()
    print("[8] 畸形数据")
    lt = new_state()
    lt.execute("storeValue = 'not a valid payload'")
    lt.execute("Advance(0.1)")
    check(call(lt, "CampusSave.Ready()") is True, "畸形串也标记就绪，不卡玩法")
    check(call(lt, "CampusSave.Get('emblems', '')") == "00000000", "回落到默认值")

    # ---------------------------------------------------------------- 9
    print()
    print("[9] 校徽串补齐")
    lt = new_state()
    lt.execute("storeValue = 'v1;e=101;q=0;a=0'")
    lt.execute("Advance(0.1)")
    check(call(lt, "CampusSave.Get('emblems', '')") == "10100000", "短串右补 0 到 8 位")

    lt = new_state()
    lt.execute("storeValue = 'v1;e=111111111111;q=0;a=0'")
    lt.execute("Advance(0.1)")
    check(call(lt, "CampusSave.Get('emblems', '')") == "11111111", "超长串截到 8 位")

    # ---------------------------------------------------------------- 10
    print()
    print("[10] 写盘失败要能重试")
    lt = new_state()
    lt.execute("storeValue = 'v1;e=00000000;q=0;a=0'")
    lt.execute("Advance(0.1)")
    lt.execute("Advance(0.1)")
    lt.execute("failSet = true")
    lt.execute("CampusSave.Set('affinity', 50)")
    lt.execute("CampusSave.Flush(true)")
    check(count_set(lt) == 1, "第一次写失败（请求发出去了）")
    lt.execute("failSet = false")
    lt.execute("Advance(5.0)")
    check(count_set(lt) == 2, "失败后下个周期自动重试，不需要调用方介入")
    check(last_set_value(lt) == "v1;e=00000000;q=0;a=50", "重试带上的是最新值")

    print()
    if ok_all:
        print("全部通过")
        return 0
    print("有失败项")
    return 1


if __name__ == "__main__":
    sys.exit(main())
