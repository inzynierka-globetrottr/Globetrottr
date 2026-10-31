"""What the measuring scripts share: the emulator, its screen coordinates and
starting the app.
"""
import os
import subprocess
import time
from io import BytesIO

import numpy as np
from PIL import Image

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


def shot():
    data = subprocess.run([ADB, *DEVICE, 'exec-out', 'screencap', '-p'], capture_output=True).stdout
    return np.asarray(Image.open(BytesIO(data)).convert('L')).astype(np.int16)


def launch(package):
    adb('shell', 'am', 'force-stop', package)
    time.sleep(1)
    adb('shell', 'monkey', '-p', package, '-c', 'android.intent.category.LAUNCHER', '1')
    time.sleep(6)
    tap(867, 2217)  # DEV MODE
    time.sleep(2)
    tap(540, 313)  # Continue without login
    time.sleep(4)
