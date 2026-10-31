"""Revealed area frame by frame around a zoom change: a dip is a flicker."""
import json
import subprocess
import sys

import numpy as np
from PIL import Image

W, H = 540, 1200
path = sys.argv[1]
dump = sys.argv[2] if len(sys.argv) > 2 else None
probe = subprocess.run(
    ['ffprobe', '-v', 'error', '-select_streams', 'v', '-show_entries', 'frame=pts_time', '-of', 'json', path],
    capture_output=True, text=True)
times = [float(f['pts_time']) for f in json.loads(probe.stdout)['frames']]
raw = subprocess.run(
    ['ffmpeg', '-v', 'error', '-i', path, '-vsync', 'passthrough', '-vf', f'scale={W}:{H}:flags=area', '-f', 'rawvideo', '-pix_fmt', 'gray', '-'],
    capture_output=True).stdout
frames = np.frombuffer(raw, np.uint8).reshape(-1, H, W)
n = min(len(times), len(frames))
area = np.array([(frames[i][180:1000] > 150).mean() for i in range(n)])
jumps = np.abs(np.diff(area))
i0 = int(np.argmax(jumps))
print('frames', n, 'area start %.4f end %.4f' % (area[0], area[-1]))
drops = [(times[i + 1] - times[0], area[i], area[i + 1]) for i in range(n - 1) if area[i + 1] < area[i] - 0.002]
print('drops of revealed area > 0.2%:', len(drops))
for t, a, b in drops[:12]:
    print('  t=%.2f %.4f -> %.4f' % (t, a, b))
largest = [(float(jumps[i]), i) for i in np.argsort(jumps)[-3:]]
print('largest steps', [(round(j, 4), round(times[i + 1] - times[0], 2)) for j, i in largest])
if dump:
    grow = np.nonzero(np.diff(area) > 0.003)[0]
    if len(grow):
        a, b = max(grow[0] - 1, 0), min(grow[-1] + 3, n - 1)
        print('zoom frames', a, b, 'times %.2f-%.2f' % (times[a] - times[0], times[b] - times[0]))
        picks = np.linspace(a, b, 6).astype(int)
        sheet = Image.new('L', (6 * 270, 600))
        for k, i in enumerate(picks):
            sheet.paste(Image.fromarray(frames[i]).resize((270, 600)), (k * 270, 0))
        sheet.save(dump)
