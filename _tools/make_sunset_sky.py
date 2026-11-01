"""
生成校园用的「夕阳」等距柱状天空贴图（2048x1024 PNG）。

Unity 侧按 latlong cubemap 导入（textureShape=Cube, generateCubemap=6），
u 与方位的对应关系来自实测探针：az = 360*u - 180（u=0.5 朝 +Z）。

画面构成：天顶深紫 → 中空品红 → 地平线橙金；日落方向的太阳圆盘 + 多层辉光；
两条云带（高空卷云 + 低空层云），云底被夕阳打亮。
"""
import math
import pathlib

import numpy as np
from PIL import Image

W, H = 2048, 1024
OUT = pathlib.Path(__file__).resolve().parent.parent / "Assets/Campus/Textures/Sky/Skybox_CampusSunset.png"

# 太阳：方位 285°（西偏北，能看到教学楼剪影），高度 14°
SUN_AZ = 240.0
SUN_EL = 18.0
U_SUN = (SUN_AZ + 180.0) / 360.0
V_SUN = 0.5 - SUN_EL / 180.0

# 渐变控制点：(仰角°, 颜色)
GRADIENT = [
    (90.0, (0.135, 0.105, 0.225)),
    (55.0, (0.200, 0.135, 0.290)),
    (35.0, (0.300, 0.165, 0.330)),
    (22.0, (0.430, 0.205, 0.315)),
    (14.0, (0.620, 0.260, 0.300)),
    (9.0,  (0.850, 0.380, 0.260)),
    (5.0,  (0.980, 0.500, 0.270)),
    (2.2,  (0.960, 0.620, 0.380)),
    (1.0,  (0.910, 0.600, 0.395)),
    (0.0,  (0.850, 0.570, 0.400)),
    (-1.0, (0.800, 0.520, 0.360)),
    (-3.0, (0.780, 0.500, 0.350)),
    (-10.0, (0.680, 0.450, 0.320)),
    (-32.0, (0.560, 0.380, 0.280)),
]


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def gradient(elev):
    """按仰角做分段线性插值，返回 (H,W,3)"""
    out = np.zeros(elev.shape + (3,), dtype=np.float32)
    for (e0, c0), (e1, c1) in zip(GRADIENT[:-1], GRADIENT[1:]):
        m = (elev <= e0) & (elev >= e1)
        t = (e0 - elev) / max(e0 - e1, 1e-6)
        t = np.clip(t, 0.0, 1.0)
        for k in range(3):
            out[..., k] = np.where(m, c0[k] + (c1[k] - c0[k]) * t, out[..., k])
    # 高于最高控制点 / 低于最低控制点
    out[elev > GRADIENT[0][0]] = GRADIENT[0][1]
    out[elev < GRADIENT[-1][0]] = GRADIENT[-1][1]
    return out


def noise_layer(h, w, cx, cy, rng):
    """x 方向周期、y 方向夹边的平滑值噪声"""
    g = rng.random((cy, cx)).astype(np.float32)
    xs = np.linspace(0, cx, w, endpoint=False)
    x0 = np.floor(xs).astype(int)
    fx = xs - x0
    x1 = (x0 + 1) % cx
    ys = np.linspace(0, cy, h, endpoint=False)
    y0 = np.floor(ys).astype(int)
    fy = ys - y0
    y1 = np.minimum(y0 + 1, cy - 1)
    fx = (fx * fx * (3 - 2 * fx)).astype(np.float32)
    fy = (fy * fy * (3 - 2 * fy)).astype(np.float32)
    a = g[np.ix_(y0, x0)]
    b = g[np.ix_(y0, x1)]
    c = g[np.ix_(y1, x0)]
    d = g[np.ix_(y1, x1)]
    top = a * (1 - fx)[None, :] + b * fx[None, :]
    bot = c * (1 - fx)[None, :] + d * fx[None, :]
    return top * (1 - fy)[:, None] + bot * fy[:, None]


def fbm(h, w, base_cx, base_cy, octaves, rng):
    total = np.zeros((h, w), dtype=np.float32)
    amp, norm = 1.0, 0.0
    for o in range(octaves):
        k = 2 ** o
        total += amp * noise_layer(h, w, base_cx * k, base_cy * k, rng)
        norm += amp
        amp *= 0.5
    return total / norm


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(20261031)

    # 坐标网格：u 横向（方位），v 纵向（0=天顶）
    u = (np.arange(W, dtype=np.float32) + 0.5) / W
    v = (np.arange(H, dtype=np.float32) + 0.5) / H
    U, V = np.meshgrid(u, v)
    az = U * 360.0 - 180.0
    elev = (0.5 - V) * 180.0

    img = gradient(elev)

    # ---- 背光侧压暗降饱和：真实夕阳的地平线亮带只在太阳那一侧 ----
    daz0 = np.abs(((az - SUN_AZ + 180.0) % 360.0) - 180.0)
    far = smoothstep(55.0, 165.0, daz0) * (1.0 - smoothstep(6.0, 34.0, elev))
    cool = np.array([0.16, 0.145, 0.235], dtype=np.float32)
    w = (0.72 * far)[..., None]
    img = img * (1.0 - w) + cool * w

    # ---- 太阳与辉光 ----
    daz = np.abs(((az - SUN_AZ + 180.0) % 360.0) - 180.0)      # 0..180
    # 经度差按纬度压缩，避免高纬度处距离算过头
    cos_el = np.cos(np.deg2rad(elev)).clip(0.05, 1.0)
    dist = np.sqrt((daz * cos_el) ** 2 + (elev - SUN_EL) ** 2)  # 近似角距（度）

    disk = smoothstep(1.15, 0.70, dist)
    glow = (0.95 * np.exp(-dist / 2.2)
            + 0.45 * np.exp(-dist / 9.0)
            + 0.20 * np.exp(-dist / 28.0)
            + 0.07 * np.exp(-dist / 70.0))
    # 地平线附近的横向暖带（夕阳把整条地平线烤红）
    band = np.exp(-np.maximum(elev, 0.0) / 7.0) * np.exp(-(daz / 80.0) ** 2)
    glow = glow + 0.30 * band
    # 辉光在地平线以下必须收掉，否则会和雾色/地面拼出一道亮缝
    glow = glow * smoothstep(-0.4, 1.4, elev)

    sun_rgb = np.array([1.00, 0.93, 0.76], dtype=np.float32)
    glow_rgb = np.array([1.00, 0.62, 0.32], dtype=np.float32)

    img += glow[..., None] * glow_rgb * 0.55
    img = img * (1.0 - disk[..., None]) + sun_rgb * disk[..., None]
    # 太阳正上方再叠一点白热核心
    core = smoothstep(0.55, 0.0, dist)
    img = img * (1.0 - core[..., None]) + np.array([1.0, 0.99, 0.95], dtype=np.float32) * core[..., None]

    # ---- 云 ----
    def cloud_layer(seed, base_cx, base_cy, octaves, lo_el, hi_el, cover_lo, cover_hi, shade):
        r = np.random.default_rng(seed)
        n = fbm(H, W, base_cx, base_cy, octaves, r)
        band_m = smoothstep(lo_el, lo_el + 4.0, elev) * smoothstep(hi_el, hi_el - 5.0, elev)
        a = smoothstep(cover_lo, cover_hi, n) * band_m
        # 越靠近太阳、越靠下，云底越亮
        lit = np.exp(-dist / 38.0) * 0.90 + np.exp(-np.maximum(elev, 0.0) / 10.0) * 0.32
        lit = np.clip(lit, 0.0, 1.0)[..., None]
        dark = np.array(shade, dtype=np.float32)
        bright = np.array([1.00, 0.63, 0.42], dtype=np.float32)
        col = dark * (1.0 - lit) + bright * lit
        # 云顶（迎光面）更暗一点，形成层次
        col = col * (1.0 - 0.22 * smoothstep(0.6, 1.0, n)[..., None])
        return np.clip(a, 0.0, 1.0)[..., None], col

    a1, c1 = cloud_layer(11, 9, 16, 5, 14.0, 55.0, 0.40, 0.60, (0.16, 0.10, 0.18))
    a2, c2 = cloud_layer(77, 15, 9, 5, 4.0, 40.0, 0.37, 0.57, (0.18, 0.11, 0.17))
    a3, c3 = cloud_layer(303, 24, 6, 4, 0.3, 12.0, 0.42, 0.66, (0.20, 0.12, 0.18))
    for a, c, k in ((a1, c1, 0.86), (a2, c2, 0.94), (a3, c3, 0.88)):
        aa = a * k
        img = img * (1.0 - aa) + c * aa

    # ---- 地平线亮边 + 轻微色散收尾 ----
    rim = np.exp(-np.abs(elev) / 2.2) * 0.06 * (0.35 + 0.65 * np.exp(-(daz0 / 65.0) ** 2))
    img += rim[..., None] * np.array([1.0, 0.72, 0.46], dtype=np.float32)

    # ---- 远山剪影：真正作用是遮住地面平面边缘那条硬线 ----
    ridge = (0.62
             + 0.30 * np.sin(np.deg2rad(az * 1.3 + 20.0))
             + 0.20 * np.sin(np.deg2rad(az * 2.9 - 60.0))
             + 0.11 * np.sin(np.deg2rad(az * 6.1 + 130.0)))
    # 第二条更远的山脊，压得更淡，拉开层次
    ridge2 = 1.15 + 0.42 * np.sin(np.deg2rad(az * 0.9 - 40.0)) + 0.18 * np.sin(np.deg2rad(az * 3.1 + 75.0))
    for top, base_dark, haze in ((ridge2, np.array([0.34, 0.25, 0.23], np.float32), 0.62),
                                 (ridge, np.array([0.26, 0.18, 0.17], np.float32), 0.34)):
        m = smoothstep(top + 0.10, top - 0.10, elev) * smoothstep(-1.4, -0.8, elev)
        warm = np.exp(-daz0 / 55.0)[..., None]
        hill = base_dark * (1.0 + 0.55 * warm)
        # 空气透视：越远越接近天色，避免看成"一堵墙"
        hill = hill * (1.0 - haze) + img * haze
        img = img * (1.0 - m[..., None]) + hill * m[..., None]

    img = np.clip(img, 0.0, 1.0)
    # 轻微 gamma：让暗部不要死黑
    img = np.power(img, 0.92)

    out = (img * 255.0 + 0.5).astype(np.uint8)
    Image.fromarray(out, "RGB").save(OUT, optimize=True)
    print("saved", OUT, out.shape)
    # 另存一张缩略图方便肉眼检查
    Image.fromarray(out, "RGB").resize((1024, 512), Image.LANCZOS).save(
        pathlib.Path(__file__).resolve().parent.parent / "_sky_sunset_preview.png")


if __name__ == "__main__":
    main()
