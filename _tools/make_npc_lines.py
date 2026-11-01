# -*- coding: utf-8 -*-
"""
把 NPC 的名字和台词画成一张 2048×2048 的图集（每格 512×128，4 列 × 16 行 = 64 格）。

为什么要预渲染成贴图：场景用的是 URP + SDK 的 World_Lit，TextMesh 用的是
GUI/Text Shader，在 URP 的离屏渲染下根本不出现（截图和实际都可能看不见）。
贴图 + quad 走的是和校名牌完全相同的管线，已经验证过能渲染、能被截图验收。

格位规则（C# 端 DouyinCampusBuilder 必须按同样的顺序算）：
  0..6    名字（NPC_01..07）
  7..     台词，按 NpcLines.txt 的出现顺序

用法：python _tools/make_npc_lines.py
"""
import io
import os

from PIL import Image, ImageDraw, ImageFont

TXT = r"D:/DouyinWorld2021/Assets/Campus/NpcLines.txt"
DST = r"D:/DouyinWorld2021/Assets/Campus/Textures/T_NpcLines.png"
FONT = r"C:/Windows/Fonts/simhei.ttf"

CELL_W, CELL_H = 512, 128
COLS, ROWS = 4, 16
W, H = CELL_W * COLS, CELL_H * ROWS        # 2048 × 2048

PAPER = (247, 241, 229)     # 暖白纸
EDGE = (168, 152, 128)      # 细边
INK = (38, 31, 26)          # 深棕字


def load_rows():
    """返回 (names, lines)。格式：NPC_01|N|林小满 / NPC_01|L|台词

    kind 以 L 开头都算台词：L 是第 1 档，L2/L3/L4 是第 2/3/4 档（好感度分档）。
    档号只影响构建脚本给 quad 起名，图集格子仍然是"先名字、后台词出现顺序"。
    """
    names, lines = [], []
    with io.open(TXT, encoding="utf-8") as f:
        for raw in f:
            s = raw.strip()
            if not s or s.startswith("#"):
                continue
            parts = s.split("|")
            if len(parts) != 3:
                continue
            who, kind, text = parts[0].strip(), parts[1].strip(), parts[2].strip()
            if kind == "N":
                names.append((who, text))
            elif kind.startswith("L"):
                lines.append((who, text))
    return names, lines


def fit_font(draw, text, max_w, max_h, start=76, min_size=26):
    """从 start 号开始往小里试，直到一行能塞进 max_w 且高度不超 max_h"""
    size = start
    while size >= min_size:
        f = ImageFont.truetype(FONT, size)
        box = draw.textbbox((0, 0), text, font=f)
        if box[2] - box[0] <= max_w and box[3] - box[1] <= max_h:
            return f
        size -= 2
    return ImageFont.truetype(FONT, min_size)


def wrap(draw, text, font, max_w):
    """按字宽折行（中文没有空格，逐字累加）"""
    rows, cur = [], ""
    for ch in text:
        trial = cur + ch
        box = draw.textbbox((0, 0), trial, font=font)
        if box[2] - box[0] > max_w and cur:
            rows.append(cur)
            cur = ch
        else:
            cur = trial
    if cur:
        rows.append(cur)
    return rows


def draw_cell(img, draw, index, text, is_name):
    col, row = index % COLS, index // COLS
    x0, y0 = col * CELL_W, row * CELL_H
    pad_x, pad_y = 14, 10

    # 纸底 + 细边：留 4px 透明边，避免采样时把相邻格吸进来
    draw.rectangle([x0 + 4, y0 + 4, x0 + CELL_W - 5, y0 + CELL_H - 5], fill=PAPER, outline=EDGE, width=2)

    inner_w = CELL_W - pad_x * 2 - 8
    inner_h = CELL_H - pad_y * 2 - 8

    if is_name:
        f = fit_font(draw, text, inner_w, inner_h, start=74)
        box = draw.textbbox((0, 0), text, font=f)
        tw, th = box[2] - box[0], box[3] - box[1]
        draw.text((x0 + CELL_W / 2 - tw / 2 - box[0], y0 + CELL_H / 2 - th / 2 - box[1]),
                  text, font=f, fill=INK)
        return

    # 台词：先定字号，再折行，两行放不下就继续缩
    size = 44
    while True:
        f = ImageFont.truetype(FONT, size)
        rows = wrap(draw, text, f, inner_w)
        line_h = size + 8
        if len(rows) * line_h <= inner_h or size <= 26:
            break
        size -= 2

    total_h = len(rows) * line_h
    y = y0 + CELL_H / 2 - total_h / 2
    for r in rows:
        box = draw.textbbox((0, 0), r, font=f)
        tw = box[2] - box[0]
        draw.text((x0 + CELL_W / 2 - tw / 2 - box[0], y - box[1]), r, font=f, fill=INK)
        y += line_h


def main():
    names, lines = load_rows()
    total = len(names) + len(lines)
    if total > COLS * ROWS:
        raise SystemExit("台词太多，图集放不下：%d > %d" % (total, COLS * ROWS))

    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    for i, (_, nm) in enumerate(names):
        draw_cell(img, draw, i, nm, True)
    for i, (_, ln) in enumerate(lines):
        draw_cell(img, draw, len(names) + i, ln, False)

    os.makedirs(os.path.dirname(DST), exist_ok=True)
    img.save(DST)

    print("names  = %d" % len(names))
    print("lines  = %d" % len(lines))
    print("cells  = %d / %d" % (total, COLS * ROWS))
    print("output = %s (%.1f KB)" % (DST, os.path.getsize(DST) / 1024))

    # 预览：把前 12 格拼成一张小图，方便肉眼看排版
    prev = Image.new("RGB", (CELL_W * 2, CELL_H * 6), (30, 30, 34))
    for i in range(min(12, total)):
        col, row = i % COLS, i // COLS
        cell = img.crop((col * CELL_W, row * CELL_H, (col + 1) * CELL_W, (row + 1) * CELL_H))
        prev.paste(cell, ((i % 2) * CELL_W, (i // 2) * CELL_H), cell)
    prev.save(r"D:/DouyinWorld2021/_npc_lines_preview.png")


if __name__ == "__main__":
    main()
