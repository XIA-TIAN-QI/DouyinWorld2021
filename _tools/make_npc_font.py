# -*- coding: utf-8 -*-
"""
把系统黑体子集化成校园 NPC 用的中文字体。

为什么要子集化：simhei.ttf 有 9.3MB、两万多字，但世界里的对话只有几百个字。
只保留 GB2312 一级常用字（3755）+ ASCII，体积可以压到 1MB 上下，
Unity 的 Font（Dynamic 模式）按需光栅化，够用且不会在运行时缺字。

用法：python _tools/make_npc_font.py
产物：Assets/Campus/Fonts/CampusSans.ttf
"""
import io
import os
import sys

from fontTools import subset
from fontTools.ttLib import TTFont

SRC_CANDIDATES = [
    r"C:/Windows/Fonts/simhei.ttf",     # 黑体：屏幕小字最清晰
    r"C:/Windows/Fonts/msyh.ttc",
    r"C:/Windows/Fonts/simsun.ttc",
]
DST = r"D:/DouyinWorld2021/Assets/Campus/Fonts/CampusSans.ttf"
DIALOG_LUA = r"D:/DouyinWorld2021/Assets/Campus/Lua/NPCTalk.lua"


def gb2312_level1() -> set:
    """GB2312 一级汉字区（0xB0A1~0xD7F9），3755 个最常用字。"""
    out = set()
    for hi in range(0xB0, 0xD8):
        for lo in range(0xA1, 0xFF):
            try:
                out.add(bytes([hi, lo]).decode("gb2312"))
            except UnicodeDecodeError:
                continue
    return out


def chars_in_lua(path: str) -> set:
    """把脚本里出现的所有字符也加进去，防止台词用了生僻字变空白。"""
    if not os.path.exists(path):
        return set()
    with io.open(path, encoding="utf-8") as f:
        return set(f.read())


def pick_source() -> str:
    for p in SRC_CANDIDATES:
        if os.path.exists(p):
            return p
    sys.exit("找不到可用的系统中文字体，请手动指定 SRC_CANDIDATES")


def main():
    src = pick_source()
    chars = set(chr(c) for c in range(0x20, 0x7F))      # ASCII 可见字符
    chars |= gb2312_level1()
    chars |= chars_in_lua(DIALOG_LUA)
    chars |= set("　，。！？：；、（）《》「」…—“”‘’·／")

    os.makedirs(os.path.dirname(DST), exist_ok=True)

    opts = subset.Options()
    opts.layout_features = ["*"]
    opts.name_IDs = ["*"]
    opts.name_legacy = True
    opts.notdef_outline = True
    opts.recalc_bounds = True
    opts.drop_tables += ["DSIG"]
    opts.desubroutinize = True

    font = subset.load_font(src, opts)
    sub = subset.Subsetter(options=opts)
    sub.populate(text="".join(sorted(chars)))
    sub.subset(font)

    # 改名，避免和系统字体混淆；同时留一个族名给 Unity 资源显示
    for rec in font["name"].names:
        if rec.nameID in (1, 4, 16):
            rec.string = "Campus Sans"
        elif rec.nameID == 6:
            rec.string = "CampusSans"

    subset.save_font(font, DST, opts)

    src_mb = os.path.getsize(src) / 1048576
    dst_mb = os.path.getsize(DST) / 1048576
    n = len(chars)
    print("source: %s (%.1f MB)" % (os.path.basename(src), src_mb))
    print("chars : %d" % n)
    print("output: %s (%.2f MB)" % (DST, dst_mb))

    # 自检：确认关键台词用字都在
    probe = "樱花大学校徽当心晚自习九点半关灯陈列架操场跑道看台夕阳"
    f2 = TTFont(DST)
    cmap = f2.getBestCmap()
    missing = [c for c in probe if ord(c) not in cmap]
    print("missing:", "".join(missing) if missing else "none")


if __name__ == "__main__":
    main()
