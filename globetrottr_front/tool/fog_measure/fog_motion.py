"""Marker motion in a recording: step per frame, hitches, and the delay between
the record button lighting up and the fog opening.

usage: fog_motion.py <run.mp4>
"""
import json
import math
import subprocess
import sys

import numpy as np

W, H = 540, 1200
path = sys.argv[1]
probe = subprocess.run(
    ['ffprobe', '-v', 'error', '-select_streams', 'v', '-show_entries', 'frame=pts_time', '-of', 'json', path],
    capture_output=True, text=True)
times = [float(f['pts_time']) for f in json.loads(probe.stdout)['frames']]
raw = subprocess.run(
    ['ffmpeg', '-v', 'error', '-i', path, '-vsync', 'passthrough', '-vf', f'scale={W}:{H}:flags=area', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'],
    capture_output=True).stdout
frames = np.frombuffer(raw, np.uint8).reshape(-1, H, W, 3)
n = min(len(times), len(frames))


def marker(frame):
    r, g, b = frame[..., 0].astype(int), frame[..., 1].astype(int), frame[..., 2].astype(int)
    mask = (b > 200) & (r < 110) & (g > 140)
    mask[:150] = False
    mask[1000:] = False
    ys, xs = np.nonzero(mask)
    return (float(xs.mean()), float(ys.mean())) if len(xs) >= 20 else None


# Record button: red ring in its box.
button = [(frames[i][60:100, 470:510, 0].astype(int) - frames[i][60:100, 470:510, 2].astype(int)).max() for i in range(n)]
on = next((i for i in range(n) if button[i] > 80), None)
gray = frames.mean(axis=3)
area = [(gray[i][180:1000] > 150).mean() for i in range(n)]
opened = next((i for i in range(1, n) if area[i] > area[0] + 0.002), None)
if on is not None and opened is not None:
    print('record button frame %d t=%.3f, fog opened frame %d t=%.3f' % (on, times[on] - times[0], opened, times[opened] - times[0]))

points = [(times[i] - times[0], marker(frames[i])) for i in range(n)]
moves = []
last = None
for t, m in points:
    if m is None:
        continue
    if last is not None and math.dist(m, last[1]) > 0.05:
        moves.append((t, t - last[0], math.dist(m, last[1])))
    last = (t, m)
if moves:
    gaps = np.array([g for _, g, _ in moves])
    steps = np.array([s for _, _, s in moves])
    print('moving frames %d, frame gap median %.0f ms p95 %.0f ms max %.0f ms' % (len(moves), np.median(gaps) * 1000, np.percentile(gaps, 95) * 1000, gaps.max() * 1000))
    print('step median %.2f px, p95 %.2f px, max %.2f px' % (np.median(steps), np.percentile(steps, 95), steps.max()))
    print('longest gaps:', [(round(t, 2), int(g * 1000)) for t, g, _ in sorted(moves, key=lambda m: -m[1])[:8]])
