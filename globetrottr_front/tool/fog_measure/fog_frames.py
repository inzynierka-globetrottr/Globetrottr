"""Measures a recorded walk: marker motion, its distance to the fog edge ahead,
and what changes on the screen while the player stands still.

usage: fog_frames.py <run.mp4> [--heading=20] [--dump=<dir>]
"""
import json
import math
import subprocess
import sys

import numpy as np

W, H = 540, 1200
path = sys.argv[1]
heading = math.radians(float(next((a[10:] for a in sys.argv if a.startswith('--heading=')), '20')))
dump = next((a[7:] for a in sys.argv if a.startswith('--dump=')), None)

probe = subprocess.run(
    ['ffprobe', '-v', 'error', '-select_streams', 'v', '-show_entries', 'frame=pts_time', '-of', 'json', path],
    capture_output=True,
    text=True,
)
times = [float(f['pts_time']) for f in json.loads(probe.stdout)['frames']]

raw = subprocess.run(
    ['ffmpeg', '-v', 'error', '-i', path, '-vsync', 'passthrough', '-vf', f'scale={W}:{H}:flags=area', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'],
    capture_output=True,
).stdout
frames = np.frombuffer(raw, np.uint8).reshape(-1, H, W, 3)
count = min(len(times), len(frames))
print('frames', count, 'of', len(times), 'duration %.1fs' % (times[count - 1] - times[0]))
print('median frame gap %.1f ms' % (np.median(np.diff(times[:count])) * 1000))


def marker(frame):
    r, g, b = frame[..., 0].astype(int), frame[..., 1].astype(int), frame[..., 2].astype(int)
    mask = (b > 200) & (r < 110) & (g > 140)
    mask[:150] = False
    mask[1000:] = False
    ys, xs = np.nonzero(mask)
    if len(xs) < 20:
        return None
    return float(xs.mean()), float(ys.mean())


gray = frames.mean(axis=3)


def gap_ahead(frame_gray, x, y):
    dx, dy = math.cos(heading), -math.sin(heading)
    for d in range(12, 400):
        px, py = int(x + dx * d), int(y + dy * d)
        if not (0 <= px < W and 0 <= py < H):
            return None
        if frame_gray[py, px] < 150:
            return d
    return None


rows = []
for i in range(count):
    m = marker(frames[i])
    rows.append((times[i], m, gap_ahead(gray[i], *m) if m else None))

moves = []
last = None
for t, m, _ in rows:
    if m and last and t > last[0]:
        moves.append((t, math.dist(m, last[1]), t - last[0]))
    if m:
        last = (t, m)
steps = np.array([d for _, d, _ in moves])
moving = steps[steps > 0.3]
print('marker moves %d, per frame: median %.2f px, max %.2f px' % (len(moving), np.median(moving) if len(moving) else 0, steps.max() if len(steps) else 0))

gaps = np.array([g for _, _, g in rows if g is not None])
print('gap to the fog edge ahead (px at 540 wide): median %.1f, min %d, max %d' % (np.median(gaps), gaps.min(), gaps.max()))

# Quiet stretches: the marker does not move, so any change is the fog itself.
print('changes while the marker stands still:')
reports = 0
ignore = None
for i in range(1, count):
    m0, m1 = rows[i - 1][1], rows[i][1]
    if not (m0 and m1) or math.dist(m0, m1) > 0.3:
        continue
    diff = np.abs(gray[i].astype(int) - gray[i - 1].astype(int))
    yy, xx = np.ogrid[:H, :W]
    diff[(xx - m1[0]) ** 2 + (yy - m1[1]) ** 2 < 28 ** 2] = 0
    diff[:180] = 0
    diff[1000:] = 0
    big = int((diff > 8).sum())
    if big > 30:
        ys, xs = np.nonzero(diff > 8)
        print('  t=%.2f changed=%d peak=%d box=(%d,%d,%d,%d)' % (times[i] - times[0], big, diff.max(), xs.min(), ys.min(), xs.max(), ys.max()))
        reports += 1
        if dump and reports <= 24:
            from PIL import Image

            Image.fromarray(frames[i - 1]).save(f'{dump}/q{reports}a.png')
            Image.fromarray(frames[i]).save(f'{dump}/q{reports}b.png')
print('quiet changes:', reports)

first_marker = next((i for i, r in enumerate(rows) if r[1]), None)
print('first marker frame', first_marker)
if dump:
    np.save(f'{dump}/gaps.npy', np.array([(t - times[0], g if g else -1) for t, _, g in rows], float))
