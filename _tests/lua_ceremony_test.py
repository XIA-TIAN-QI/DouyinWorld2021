"""
CampusCeremony.lua 逻辑测试（不需要 Unity 运行时）

用 lupa 起一个真实 Lua 解释器，mock 掉烟花节点树、任务状态、存档层和女主角，
检查毕业典礼这条演出线：

  [1] 没集齐 → 什么都不发生
  [2] 集齐 + 存档未标记 → 开演：弹提示、通知女主角
  [3] 烟花时序：升空弹先出现，到顶后隐藏，火星爆散并逐渐缩小
  [4] 放完 MAX_SHOTS 发后收尾，并把 ceremony=1 写进存档
  [5] 存档已标记 → 重进世界不重播
  [6] 存档层迟迟没就绪 → 等 SAVE_WAIT 后仍然要演（宁可多演一次）
  [7] 场景里没有烟花节点 → 不崩，演出照样走完（降级）
"""
import pathlib
import sys

import lupa

HERE = pathlib.Path(__file__).resolve().parent
SCRIPT = HERE.parent / "Assets" / "Campus" / "Lua" / "CampusCeremony.lua"

HARNESS = r"""
log = {}
toastLog = {}
local real_print = print
print = function(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[#parts + 1] = tostring(select(i, ...)) end
    log[#log + 1] = table.concat(parts, " ")
end

local function v3(x, y, z) return { x = x, y = y, z = z } end
testVec3 = v3

CS = { UnityEngine = { Time = { time = 0, frameCount = 0, deltaTime = 0 } } }
CS.UnityEngine.Vector3 = setmetatable({}, {
    __call = function(_, x, y, z) return v3(x, y, z) end,
})
CS.DouyinUtility = {
    Toast = function(s) toastLog[#toastLog + 1] = s end,
}
CS.UnityEngine.AudioSource = { __kind = "AudioSource" }
function typeof(t) return t end

-- ---------- 烟花节点树 ----------
local function newT(name)
    local t = { name = name, active = true, children = {} }
    t.position = v3(0, 0, 0)
    t.localScale = v3(1, 1, 1)
    t.gameObject = {
        name = name,
        SetActive = function(self, v) t.active = v end,
    }
    function t:Find(n) return self.children[n] end
    return t
end

fireworksExists = true
fireworksRoot = newT("Fireworks")
rocketT = newT("Firework_Rocket")
rocketT.active = false
fireworksRoot.children["Firework_Rocket"] = rocketT
sparkT = {}
for i = 1, 12 do
    local n = string.format("Firework_Spark%02d", i)
    local s = newT(n)
    s.active = false
    fireworksRoot.children[n] = s
    sparkT[i] = s
end

CS.UnityEngine.GameObject = {
    Find = function(n)
        if n == "Fireworks" then
            if not fireworksExists then return nil end
            return { name = "Fireworks", transform = fireworksRoot }
        end
        if n == "CampusAudio" then
            if not audioExists then return nil end
            return { name = "CampusAudio", transform = campusAudioT }
        end
        return nil
    end,
}

-- ---------- 音频层 ----------
audioExists = true
audioSources = {}
campusAudioT = newT("CampusAudio")
function mkAudioNode(name, hasClip)
    local s = { name = name, played = 0, volume = 0.55,
                clip = hasClip and (name .. ".ogg") or nil }
    function s:Play() s.played = s.played + 1 end
    audioSources[name] = s
    local t = newT(name)
    t.gameObject.GetComponent = function(self, typ) return s end
    campusAudioT.children[name] = t
end
mkAudioNode("BGM_Ambient", true)
mkAudioNode("BGM_Ceremony", true)
mkAudioNode("SFX_Firework", true)

-- ---------- 外部依赖 ----------
questComplete = false
questMock = {}
function questMock.IsComplete(self) return questComplete end
_G["CampusQuest"] = questMock

saveMock = { ready = true, ceremony = 0, flushes = 0 }
function saveMock.Ready() return saveMock.ready end
function saveMock.Get(k, d)
    local v = saveMock[k]
    if v == nil then return d end
    return v
end
function saveMock.Set(k, v) saveMock[k] = v end
function saveMock.Flush(force) saveMock.flushes = saveMock.flushes + 1 end
_G["CampusSave"] = saveMock

starCalled = false
starMaxed = true          -- 好感是否满档：决定她来不来
starMock = {}
function starMock.OnCeremony() starCalled = true end
function starMock.IsMax() return starMaxed end
_G["CampusStar"] = starMock

frameNo = 0
function Advance(dt)
    frameNo = frameNo + 1
    CS.UnityEngine.Time.time = CS.UnityEngine.Time.time + dt
    CS.UnityEngine.Time.frameCount = frameNo
    LateUpdate()
end
function Run(sec)
    local n = math.floor(sec / 0.1 + 0.5)
    for i = 1, n do Advance(0.1) end
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


def count_log(lt, pat):
    lt.globals().pat = pat
    return lt.eval("(function() local n=0 for _,l in ipairs(log) do "
                   "if string.find(l, pat, 1, true) then n=n+1 end end return n end)()")


def toasts(lt):
    return list(call(lt, "toastLog").values())


def any_active_spark(lt):
    return call(lt, "(function() for i=1,12 do if sparkT[i].active then return true end end return false end)()")


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
    print("[1] 没集齐：什么都不发生")
    lt = new_state()
    lt.execute("questComplete = false")
    lt.execute("Run(8.0)")
    check(len(toasts(lt)) == 0, "没弹任何提示")
    check(call(lt, "starCalled") is False, "没有惊动女主角")
    check(call(lt, "rocketT.active") is False, "升空弹没出现")

    # ---------------------------------------------------------------- 2
    print()
    print("[2] 集齐 + 没播过：开演")
    lt = new_state()
    lt.execute("questComplete = true")
    lt.execute("saveMock.ceremony = 0")
    lt.execute("starMaxed = true")
    lt.execute("Advance(0.1)")
    check(any("毕业典礼开始了" in t for t in toasts(lt)), "弹了开演提示")
    check(call(lt, "starCalled") is True, "通知了女主角（她会走到广场）")
    check(any("她也来了" in t for t in toasts(lt)), "提示里点明她来了")

    # ---------------------------------------------------------------- 3
    print()
    print("[3] 烟花时序")
    lt.execute("Run(2.7)")           # 越过 FIREWORK_DELAY=2.6
    check(call(lt, "rocketT.active") is True, "升空弹已出现")
    check(count_log(lt, "第 1 发") == 1, "放了第一发")
    lt.execute("Run(0.7)")           # 越过 ROCKET_LIFE=0.5
    check(call(lt, "rocketT.active") is False, "升空弹到顶后隐藏")
    check(any_active_spark(lt) is True, "火星已经爆散")
    # 火星应该越飞越小
    lt.execute("s0 = sparkT[1].localScale.x")
    lt.execute("Run(1.0)")
    lt.execute("s1 = sparkT[1].localScale.x")
    check(call(lt, "s1") < call(lt, "s0"), "火星在缩小（%.3f → %.3f）" % (call(lt, "s0"), call(lt, "s1")))

    # ---------------------------------------------------------------- 4
    print()
    print("[4] 放完收尾并写存档")
    lt.execute("Run(20.0)")
    check(count_log(lt, "发，落点") == 4, "正好放了 4 发，实际 " + str(count_log(lt, "发，落点")))
    check(any("典礼结束" in t for t in toasts(lt)), "弹了收尾提示")
    check(call(lt, "saveMock.ceremony") == 1, "ceremony 标记写成 1")
    check(call(lt, "saveMock.flushes") >= 1, "标记落盘了")
    check(any_active_spark(lt) is False, "粒子全部回收隐藏")

    # ---------------------------------------------------------------- 5
    print()
    print("[5] 已经播过：重进世界不重播")
    lt = new_state()
    lt.execute("questComplete = true")
    lt.execute("saveMock.ceremony = 1")
    lt.execute("Run(8.0)")
    check(len(toasts(lt)) == 0, "没重复弹提示")
    check(count_log(lt, "发，落点") == 0, "没放烟花")

    # ---------------------------------------------------------------- 6
    print()
    print("[6] 存档层没就绪：等一会儿仍然要演")
    lt = new_state()
    lt.execute("questComplete = true")
    lt.execute("saveMock.ready = false")
    lt.execute("Run(3.0)")
    check(len(toasts(lt)) == 0, "3 秒内还在等存档（不急着演）")
    lt.execute("Run(4.0)")           # 越过 SAVE_WAIT=6
    check(any("毕业典礼开始了" in t for t in toasts(lt)), "等超时后仍然开演（不能什么都不给玩家）")

    # ---------------------------------------------------------------- 7
    print()
    print("[7] 场景里没有烟花节点：降级但不能崩")
    lt = new_state()
    lt.execute("fireworksExists = false")
    lt.execute("questComplete = true")
    lt.execute("Awake()")            # 重新 Awake，这次找不到父节点
    lt.execute("Run(25.0)")
    check(call(lt, "rocket") is None, "确实没拿到节点")
    check(any("典礼结束" in t for t in toasts(lt)), "没有烟花也能正常收尾")

    # ---------------------------------------------------------------- 8
    print()
    print("[8] 好感没满：她不来了，只剩烟花")
    lt = new_state()
    lt.execute("questComplete = true")
    lt.execute("starMaxed = false")
    lt.execute("Advance(0.1)")
    check(any("毕业典礼开始了" in t for t in toasts(lt)), "典礼照样开始")
    check(call(lt, "starCalled") is False, "没叫她（第 4 档那句才有约束力）")
    check(not any("她也来了" in t for t in toasts(lt)), "提示里不点明她来")
    lt.execute("Run(20.0)")
    check(any("典礼结束" in t for t in toasts(lt)), "没有她也照样收尾")

    # ---------------------------------------------------------------- 9
    print()
    print("[9] 典礼 BGM：主题起、日常压低、每发一声烟花")
    lt = new_state()
    lt.execute("questComplete = true")
    lt.execute("Advance(0.1)")
    check(call(lt, "audioSources['BGM_Ceremony'].played") == 1, "开演就放典礼主题")
    check(call(lt, "audioSources['BGM_Ambient'].volume") == 0.18,
        "日常 BGM 被压低（%.2f）" % call(lt, "audioSources['BGM_Ambient'].volume"))
    lt.execute("Run(20.0)")          # 4 发全部放完
    check(call(lt, "audioSources['SFX_Firework'].played") == 4,
        "每发烟花一声，共 %d 声" % call(lt, "audioSources['SFX_Firework'].played"))

    # ---------------------------------------------------------------- 10
    print()
    print("[10] 没有典礼主题文件：不动日常 BGM（否则像设备坏了）")
    lt = new_state()
    lt.execute("questComplete = true")
    lt.execute("mkAudioNode('BGM_Ceremony', false)")   # 音源在，但没 clip
    lt.execute("Advance(0.1)")
    check(call(lt, "audioSources['BGM_Ceremony'].played") == 0, "没 clip 就不放")
    check(call(lt, "audioSources['BGM_Ambient'].volume") == 0.55, "日常 BGM 音量没被动")

    # ---------------------------------------------------------------- 11
    print()
    print("[11] 整个音频层缺失：演出照样走完（降级）")
    lt = new_state()
    lt.execute("audioExists = false")
    lt.execute("questComplete = true")
    lt.execute("Run(25.0)")
    check(any("典礼结束" in t for t in toasts(lt)), "没音频也正常收尾")
    check(count_log(lt, "发，落点") == 4, "烟花照放")

    print()
    if ok_all:
        print("全部通过")
        return 0
    print("有失败项")
    return 1


if __name__ == "__main__":
    sys.exit(main())
