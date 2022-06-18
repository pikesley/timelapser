import sys
from datetime import datetime
from pathlib import Path
from time import sleep

from picamera import PiCamera

photos_dir = "/home/pi/photos"

Path(photos_dir).mkdir(exist_ok=True)

delay = 0
if len(sys.argv) > 1:
    delay = int(sys.argv[1])

sleep(delay)

timestamp = datetime.now().isoformat()

camera = PiCamera()

camera.resolution = (3280, 2464)
camera.iso = 400

camera.start_preview()
sleep(5)
camera.capture(f"{photos_dir}/{timestamp}.jpg")
camera.stop_preview()
camera.close()
