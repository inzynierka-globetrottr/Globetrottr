"""Walks with flushes switched off in the build, then stops recording: the whole
walk goes from new fog to tiles at once. Compares the screen before and after.

usage: fog_handover.py <package> <lat> <lng> <dir> [--launch] [--heading=20]
"""
import math
import os
import sys
import time

import numpy as np
from PIL import Image

from fog_common import RECENTER, RECORD, geo, launch, shot, tap

package, lat, lng, out = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), sys.argv[4]
heading = math.radians(float(next((a[10:] for a in sys.argv if a.startswith('--heading=')), '20')))
os.makedirs(out, exist_ok=True)
if '--launch' in sys.argv:
    launch(package)

geo(lat, lng)
time.sleep(2)
tap(*RECENTER)
time.sleep(3)
tap(*RECORD)
time.sleep(2)
for i in range(1, 13):
    started = time.time()
    north, east = i * 14 * math.sin(heading), i * 14 * math.cos(heading)
    geo(lat + north / 111319.49, lng + east / (111319.49 * math.cos(math.radians(lat))))
    time.sleep(max(0, 1 - (time.time() - started)))

time.sleep(2.5)
a = shot()
tap(*RECORD)
time.sleep(3)
b = shot()

mask = np.ones(a.shape, bool)
mask[:400] = False
mask[2000:] = False
yy, xx = np.nonzero(np.abs(b - a) * mask > 3)
print('whole walk handed to tiles: changed>3: %d  >8: %d  >16: %d  peak %d' % (
    int((np.abs(b - a) * mask > 3).sum()), int((np.abs(b - a) * mask > 8).sum()),
    int((np.abs(b - a) * mask > 16).sum()), int((np.abs(b - a) * mask).max())))
Image.fromarray(a.astype(np.uint8)).save(f'{out}/still_a.png')
Image.fromarray(b.astype(np.uint8)).save(f'{out}/still_b.png')
d = b - a
vis = np.zeros((*a.shape, 3), np.uint8)
vis[..., 0] = np.clip(d * 12, 0, 255)
vis[..., 2] = np.clip(-d * 12, 0, 255)
vis[..., 1] = (a // 3).astype(np.uint8)
Image.fromarray(vis).save(f'{out}/still_diff.png')
