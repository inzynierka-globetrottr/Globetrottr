"""Walks, stops, and compares lossless screenshots while the player stands
still, so that only what a flush changes is left.

usage: fog_still.py <package> <lat> <lng> [--launch] [--dump=<dir>]
"""
import math
import sys
import time

import numpy as np
from PIL import Image

from fog_common import RECENTER, RECORD, geo, launch, shot, tap

package, lat, lng = sys.argv[1], float(sys.argv[2]), float(sys.argv[3])
dump = next((a[7:] for a in sys.argv if a.startswith('--dump=')), None)
if '--launch' in sys.argv:
    launch(package)
geo(lat, lng)
time.sleep(2)
tap(*RECENTER)
time.sleep(3)
tap(*RECORD)
time.sleep(2)
heading = math.radians(20)
for i in range(1, 13):
    started = time.time()
    north, east = i * 14 * math.sin(heading), i * 14 * math.cos(heading)
    geo(lat + north / 111319.49, lng + east / (111319.49 * math.cos(math.radians(lat))))
    time.sleep(max(0, 1 - (time.time() - started)))

time.sleep(2.0)  # the player arrives
frames = [(time.time(), shot())]
for _ in range(9):
    frames.append((time.time(), shot()))
    time.sleep(0.25)
tap(*RECORD)

mask = np.ones(frames[0][1].shape, bool)
mask[:400] = False
mask[2000:] = False
start = frames[0][0]
worst = (0, None)
for i in range(1, len(frames)):
    diff = np.abs(frames[i][1] - frames[i - 1][1]) * mask
    count = int((diff > 3).sum())
    print('%.1fs changed>3: %d  >8: %d  >16: %d  peak %d' % (frames[i][0] - start, count, (diff > 8).sum(), (diff > 16).sum(), diff.max()))
    if count > worst[0]:
        worst = (count, i)
if dump and worst[1]:
    i = worst[1]
    a, b = frames[i - 1][1], frames[i][1]
    Image.fromarray(a.astype(np.uint8)).save(f'{dump}/still_a.png')
    Image.fromarray(b.astype(np.uint8)).save(f'{dump}/still_b.png')
    d = b - a
    vis = np.zeros((*a.shape, 3), np.uint8)
    vis[..., 0] = np.clip(d * 12, 0, 255)
    vis[..., 2] = np.clip(-d * 12, 0, 255)
    vis[..., 1] = (a // 3).astype(np.uint8)
    Image.fromarray(vis).save(f'{dump}/still_diff.png')
