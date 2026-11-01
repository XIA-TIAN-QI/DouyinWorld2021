# -*- coding: utf-8 -*-
"""生成「樱花大学」校名牌贴图（4:1），供 M_SignText 材质使用。
输出：Assets/Campus/Textures/T_SchoolSign.png
字体：行楷 STXINGKA（没有就退到微软雅黑粗体）
"""
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

# 主标题
text = "樱花大学"
fs = 208
font, used = pick_font(fs)
track = 0.20                      # 字间距（em）
adv = [d.textlength(ch, font=font) for ch in text]
total = sum(adv) + fs * track * (len(text) - 1)
x = (W - total) / 2
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

# 拉丁副标题
sub = "SAKURA  UNIVERSITY"
try:
    sfont = ImageFont.truetype(r"C:/Windows/Fonts/Deng.ttf", 30)
except Exception:
    sfont = font
sw = d.textlength(sub, font=sfont)
d.text(((W - sw) / 2, H - 92), sub, font=sfont, fill=(196, 160, 104))
d.line([W * 0.5 - 150, H - 104, W * 0.5 + 150, H - 104], fill=GOLD_D, width=2)

img.save(OUT, "PNG")
print("saved", OUT, img.size, "font=", used)
