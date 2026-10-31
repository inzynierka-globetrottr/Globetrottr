"""Drives one recorded walk in the app on the emulator and records the screen.

usage: fog_run.py <package> <out.mp4> <start_lat> <start_lng> [--launch] [--zoom]
"""
import math
import os
import subprocess
import sys
import time

ADB = os.path.expandvars(r'%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe')
DEVICE = ['-s', 'emulator-5554']
RECORD = (980, 162)
RECENTER = (980, 320)


def adb(*args, **kw):
    return subprocess.run([ADB, *DEVICE, *args], capture_output=True, text=True, **kw)


def tap(x, y):
    adb('shell', 'input', 'tap', str(x), str(y))


def geo(lat, lng):
    adb('emu', 'geo', 'fix', f'{lng:.7f}', f'{lat:.7f}')


def offset(lat, lng, north, east):
    return (
        lat + north / 111319.49,
        lng + east / (111319.49 * math.cos(math.radians(lat))),
    )


def launch(package):
    adb('shell', 'am', 'force-stop', package)
    time.sleep(1)
    adb('shell', 'monkey', '-p', package, '-c', 'android.intent.category.LAUNCHER', '1')
    time.sleep(6)
    tap(867, 2217)  # DEV MODE
    time.sleep(2)
    tap(540, 313)  # Continue without login
    time.sleep(4)


def main():
    package, out, lat, lng = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4])
    flags = sys.argv[5:]
    step = 14.0
    heading = math.radians(float(next((f[10:] for f in flags if f.startswith('--heading=')), '20')))
    steps = int(next((f[8:] for f in flags if f.startswith('--steps=')), '18'))

    if '--launch' in flags:
        launch(package)
    geo(lat, lng)
    time.sleep(2)
    tap(*RECENTER)
    time.sleep(3)

    adb('shell', 'rm', '-f', '/sdcard/run.mp4')
    recorder = subprocess.Popen(
        [ADB, *DEVICE, 'shell', 'screenrecord', '--bit-rate', '20000000', '--time-limit', '60', '/sdcard/run.mp4']
    )
    time.sleep(1.5)
    tap(*RECORD)
    time.sleep(3)  # standing still: what recording shows at once

    for i in range(1, steps + 1):
        started = time.time()
        north = i * step * math.sin(heading)
        east = i * step * math.cos(heading)
        geo(*offset(lat, lng, north, east))
        if '--zoom' in flags and i == steps // 2:
            adb('shell', 'input tap 540 1400; input tap 540 1400')
        time.sleep(max(0, 1.0 - (time.time() - started)))

    time.sleep(7)  # standing still: the flush
    tap(*RECORD)
    time.sleep(2)
    adb('shell', 'pkill', '-INT', 'screenrecord')
    recorder.wait(timeout=20)
    time.sleep(1)
    adb('pull', '/sdcard/run.mp4', out)
    print('recorded', out, os.path.getsize(out) // 1024, 'KB')


main()
