# Time-lapser

## Configure your Camera-Pi

From a box-fresh install of [Raspberry Pi OS Bullseye](https://www.raspberrypi.com/news/raspberry-pi-os-debian-bullseye/) (no desktop):

### Set the hostname

```
sudo raspi-config nonint do_hostname lapsecam
```

### Enable the camera

```
echo "" | sudo tee -a /boot/config.txt
echo "# raspi-config is a confusing mess" | sudo tee -a /boot/config.txt
echo "[all]" | sudo tee -a /boot/config.txt
echo "gpu_mem=128" | sudo tee -a /boot/config.txt
echo "start_x=1" | sudo tee -a /boot/config.txt
echo "camera_auto_detect=0" | sudo tee -a /boot/config.txt
```

> This is slighty heavy-handed and non-idempotent, but it appears to be [what `raspi-config` is doing behind the scenes](https://raspberrypi.stackexchange.com/questions/14229/how-can-i-enable-the-camera-without-using-raspi-config)

### Reboot it

```
sudo reboot
```

## Build and run the container

```
make build
make run STILLS=/Users/sam/Desktop/stills
```

where `STILLS` is the location where you'd like to store the timelapse photos.

### Push code to the Pi

At the top of the [`Makefile`](Makefile), set `PI` to the name of your Pi, e.g. `PI=lapsecam.local`, then

```
make push-code
```

## Aim the camera

Back on the Pi, run

```
make aim
```

There should now be streaming video at [https://lapsecam.local:8000/](https://lapsecam.local:8000/), so you can aim and focus your camera.

## Setup the cronjobs

There's a `make` target that creates the cronjobs:

```
make cron
```

By default, this takes 4 photos per minute, one every 15 seconds, but this is configurable. For example:

```
make cron PHOTOS_PER_MINUTE=7
```

will take one photo every 8-ish seconds. Attempting to take too many photos per minute will cause things to break, so be sensible.

## Pull the photos locally

On the container:

```
make pull-photos
```

This pulls the photos from thr Pi into `/opt/stills` (where `${STILLS}` is mounted). The `rsync` is running with bandwidth-limiting enabled, because letting it run full-tilt seems to overwhelm the Pi, which overheats and shuts down. The amount of limiting is configurable as `BWLIMIT` at the top of the `Makefile`.

## Make a movie

Once you have all the photos locally, you can make them into a movie:

```
make movie
```

This runs [`ffmpeg`](https://ffmpeg.org/) over the images in `/opt/stills` and dumps a movie at `movies/movie-<timestamp>.mp4`, using these magic spells:

```
FRAMES_PER_SECOND=25

-c:v libx264 -vf fps=fps=${FRAMES_PER_SECOND} -pix_fmt yuv420p
```

which may or may not be good, `ffmpeg` is voodoo.

## Incremental pull

To incrementally pull the pictures as they're created, try something like

```
while [ 1 ] ; do make pull-photos ; sleep 60 ; done
```

This will (in theory) eventually catch up.
