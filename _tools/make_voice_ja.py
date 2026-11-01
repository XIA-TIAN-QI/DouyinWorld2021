# -*- coding: utf-8 -*-
"""批量生成黄思诚日语台词配音（Edge TTS / ja-JP-NanamiNeural）

读 Voice/NPC_08/_manifest_ja.txt（NPC_08/Line_x_xx|日文台词），
每句按语速阶梯 [+10%, +18%, +25%, +30%] 逐档尝试，
取「能塞进时长上限的最慢一档」，保证听感自然。
"""
import asyncio, io, os, sys
import edge_tts
from mutagen.mp3 import MP3

VOICE = 'ja-JP-NanamiNeural'
MANIFEST = 'D:/DouyinWorld2021/Assets/Campus/Audio/Voice/NPC_08/_manifest_ja.txt'
OUT = 'D:/DouyinWorld2021/Assets/Campus/Audio/Voice/NPC_08'
LIMIT = 5.6            # 气泡将放宽到 6.0s，留 0.4s 余量
RATES = ['+10%', '+18%', '+25%', '+30%']

async def synth(text, rate, path):
    c = edge_tts.Communicate(text, VOICE, rate=rate)
    await c.save(path)

def dur(path):
    return MP3(path).info.length

async def main():
    rows = []
    for raw in io.open(MANIFEST, encoding='utf-8'):
        raw = raw.strip()
        if not raw or raw.startswith('#'):
            continue
        name, text = raw.split('|', 1)
        name = name.strip().split('/')[-1]   # 清单里是 NPC_08/Line_x_xx，取文件名部分
        rows.append((name, text.strip()))
    print('清单 %d 句' % len(rows))

    ok, fail = 0, []
    for i, (name, text) in enumerate(rows, 1):
        dest = os.path.join(OUT, name + '.mp3')
        chosen = None
        for rate in RATES:
            tmp = dest + '.tmp.mp3'
            for attempt in range(3):
                try:
                    await synth(text, rate, tmp)
                    break
                except Exception as e:
                    print('  重试 %s %s: %s' % (name, rate, e))
                    await asyncio.sleep(2)
            if not os.path.exists(tmp):
                continue
            d = dur(tmp)
            if d <= LIMIT:
                os.replace(tmp, dest)
                chosen = (rate, d)
                break
            os.remove(tmp)
        if chosen:
            ok += 1
            print('[%2d/22] %-14s %-5s %.2fs  %s' % (i, name, chosen[0], chosen[1], text[:22]))
        else:
            fail.append(name)
            print('[%2d/22] %-14s 全部语速都超时！' % (i, name))
        await asyncio.sleep(0.6)   # 温和限速，别触发风控

    print()
    print('完成 %d/%d' % (ok, len(rows)))
    if fail:
        print('超时未完成：', ', '.join(fail))
        sys.exit(1)

asyncio.run(main())
