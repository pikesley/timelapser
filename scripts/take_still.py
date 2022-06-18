import sys
from datetime import datetime
from pathlib import Path
from time import sleep

from picamera import PiCamera  # pylint: disable=E0401

PHOTOS_DIR = "/home/pi/photos"

Path(PHOTOS_DIR).mkdir(exist_ok=True)

DELAY = 0
if len(sys.argv) > 1:
    DELAY = int(sys.argv[1])

sleep(DELAY)

timestamp = datetime.now().isoformat()

camera = PiCamera()

camera.resolution = (3280, 2464)
camera.iso = 400

camera.start_preview()
sleep(5)
camera.capture(f"{PHOTOS_DIR}/{timestamp}.jpg")
camera.stop_preview()
camera.close()
