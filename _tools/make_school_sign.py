# -*- coding: utf-8 -*-
"""生成「樱花大学」校名牌贴图（4:1），供 M_SignText 材质使用。
输出：Assets/Campus/Textures/T_SchoolSign.png
字体：行楷 STXINGKA（没有就退到微软雅黑粗体）

左侧带圆形校徽（双金环 + 五瓣樱），文字整体右移给徽章让位。
材质额度 20/20 已满，所以校徽直接烘进这张贴图，不加新材质/新 quad。
"""
import math
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1536, 384
OUT = r"D:/DouyinWorld2021/Assets/Campus/Textures/T_SchoolSign.png"

FONT_CANDIDATES = [
    r"C:/Windows/Fonts/STXINGKA.TTF",
    r"C:/Windows/Fonts/STKAITI.TTF",
    r"C:/Windows/Fonts/msyhbd.ttc",
]


def pick_font(size):
    for p in FONT_CANDIDATES:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size), p
            except Exception:
                pass
    return ImageFont.load_default(), "default"


def vgrad(w, h, top, bot):
    img = Image.new("RGB", (1, h))
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        px[0, y] = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
    return img.resize((w, h), Image.BILINEAR)


img = vgrad(W, H, (78, 20, 26), (46, 12, 18))
d = ImageDraw.Draw(img)

# 四角轻微压暗，避免整块死平
vig = Image.new("L", (W, H), 0)
dv = ImageDraw.Draw(vig)
dv.ellipse([-W * 0.25, -H * 0.9, W * 1.25, H * 1.9], fill=60)
vig = vig.filter(ImageFilter.GaussianBlur(60))
img = Image.composite(img, Image.new("RGB", (W, H), (28, 7, 11)), vig.point(lambda v: 255 - v))
d = ImageDraw.Draw(img)

GOLD = (232, 196, 128)
GOLD_D = (150, 112, 56)


def frame(inset, width, color):
    d.rectangle([inset, inset, W - inset - 1, H - inset - 1], outline=color, width=width)


frame(10, 6, GOLD_D)
frame(22, 3, GOLD)

# ---------------------------------------------------------------- 校徽（左侧圆形）
# 五瓣樱：五片心形花瓣绕中心均布 + 花心小圆 + 外圈双环。
# 全部用多边形硬画，不依赖字体；金色沿用牌匾的 GOLD/GOLD_D 做明暗两档。


def sakura_petal(cx, cy, r, angle_deg):
    """一片花瓣：从中心指向 angle_deg 的圆头泪滴形"""
    a = math.radians(angle_deg)
    ux, uy = math.cos(a), math.sin(a)          # 指向外
    tip = (cx + ux * r, cy + uy * r)
    side = 0.42 * r
    px, py = -uy, ux                            # 垂直方向
    waist = (cx + ux * r * 0.30, cy + uy * r * 0.30)
    bulge = (cx + ux * r * 0.68 + px * side, cy + uy * r * 0.68 + py * side)
    bulge2 = (cx + ux * r * 0.68 - px * side, cy + uy * r * 0.68 - py * side)
    return [tip, bulge, waist, bulge2]


def draw_emblem(d, cx, cy, r):
    # 底：稍亮的暗红圆盘（和牌匾底色区分开）
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(96, 26, 32), outline=GOLD_D, width=7)
    # 双环
    d.ellipse([cx - r + 14, cy - r + 14, cx + r - 14, cy + r - 14], outline=GOLD, width=5)
    d.ellipse([cx - r + 30, cy - r + 30, cx + r - 30, cy + r - 30], outline=GOLD_D, width=3)
    # 五瓣樱（金），从正上方开始转
    petal_r = (r - 52) * 0.62
    for i in range(5):
        ang = -90 + i * 72
        pts = sakura_petal(cx, cy, petal_r + 18, ang)
        d.polygon(pts, fill=GOLD)
    # 花心：小暗红圆盖住花瓣交汇处，再点金芯
    d.ellipse([cx - 26, cy - 26, cx + 26, cy + 26], fill=(96, 26, 32), outline=GOLD_D, width=3)
    d.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=GOLD)
    # 环外点缀：左右各三枚小金点，节奏感
    for sx in (-1, 1):
        for k, rr in ((1.16, 8), (1.30, 6), (1.44, 4)):
            px = cx + sx * r * rr
            d.ellipse([px - rr, cy - rr, px + rr, cy + rr], fill=GOLD_D)


draw_emblem(d, 208, H / 2, 150)

# 徽章与文字之间一条竖向金线
d.line([392, 60, 392, H - 60], fill=GOLD_D, width=3)

# 主标题（右移：在徽章右侧的剩余区域里居中）
text = "樱花大学"
fs = 208
font, used = pick_font(fs)
track = 0.20                      # 字间距（em）
adv = [d.textlength(ch, font=font) for ch in text]
total = sum(adv) + fs * track * (len(text) - 1)
x = 392 + (W - 392 - total) / 2
y = 52

for i, ch in enumerate(text):
    # 先画一层深色描边，再叠金色，模拟金属字的厚度
    for dx, dy in ((-3, 0), (3, 0), (0, -3), (0, 3), (-2, -2), (2, 2)):
        d.text((x + dx, y + dy), ch, font=font, fill=(58, 16, 20))
    d.text((x, y), ch, font=font, fill=GOLD)
    # 上半部分提亮，做出金属受光
    mask = Image.new("L", (W, H), 0)
    dm = ImageDraw.Draw(mask)
    dm.text((x, y), ch, font=font, fill=255)
    ImageDraw.Draw(mask).rectangle([0, y + int(fs * 0.42), W, H], fill=0)
    mask = mask.filter(ImageFilter.GaussianBlur(7)).point(lambda v: int(v * 0.45))
    light = Image.new("RGB", (W, H), (255, 238, 196))
    img.paste(light, (0, 0), mask)
    d = ImageDraw.Draw(img)
    x += adv[i] + fs * track

# 拉丁副标题（跟随主标题在右半区居中）
sub = "SAKURA  UNIVERSITY"
try:
    sfont = ImageFont.truetype(r"C:/Windows/Fonts/Deng.ttf", 30)
except Exception:
    sfont = font
sw = d.textlength(sub, font=sfont)
sub_cx = 392 + (W - 392) / 2
d.text((sub_cx - sw / 2, H - 92), sub, font=sfont, fill=(196, 160, 104))
d.line([sub_cx - 150, H - 104, sub_cx + 150, H - 104], fill=GOLD_D, width=2)

img.save(OUT, "PNG")
print("saved", OUT, img.size, "font=", used)
