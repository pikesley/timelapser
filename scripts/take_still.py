import sys
from datetime import datetime
from time import sleep

from picamera import PiCamera  # pylint: disable=E0401

RESOLUTION = (3280, 2464)
ISO = 400
WARM_UP_TIME = 2
PHOTOS_DIR = "/home/pi/photos"  # this is created by `make setup`


def take_photo(delay):
    """Take a photo after a delay."""
    sleep(delay)
    timestamp = datetime.now().isoformat()

    camera = PiCamera()
    camera.resolution = RESOLUTION
    camera.iso = ISO

    camera.start_preview()
    sleep(WARM_UP_TIME)
    camera.capture(f"{PHOTOS_DIR}/{timestamp}.jpg")
    camera.stop_preview()
    camera.close()


if __name__ == "__main__":
    take_photo(int(sys.argv[1]))
