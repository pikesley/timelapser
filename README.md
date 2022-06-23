[![CI](../../actions/workflows/main.yml/badge.svg)](../../actions/workflows/main.yml)

_Make timelapse movies with a camera-equipped Raspberry Pi_

## Configure your Camera-Pi

From a box-fresh install of [Raspberry Pi OS Bullseye](https://www.raspberrypi.com/news/raspberry-pi-os-debian-bullseye/) (no desktop):

### Set the hostname

```
sudo raspi-config nonint do_hostname lapsecam
```

### Enable the camera

```
cat <<EOF | sudo tee -a /boot/config.txt

# raspi-config is a confusing mess
[all]
gpu_mem=128
start_x=1
camera_auto_detect=0
EOF
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

At the top of the [`Makefile`](Makefile), set `PI` to the name of your Pi, e.g. `PI=lapsecam.local`, then copy your `ssh` key over:

```
make send-key
```

and push the code:

```
make push-code
```

## Install dependencies and aim the camera

Back on the Pi, run

```
make setup
```

This installs everything, then starts a webserver so that there should be streaming video at [https://lapsecam.local:8000/](https://lapsecam.local:8000/), allowing you to aim and focus your camera.

> It pulls the sreaming server from [here](https://github.com/RuiSantosdotme/Random-Nerd-Tutorials/blob/master/Projects/rpi_camera_surveillance_system.py) - this code has no license that I could find, so I'm not directly including it

## Set-up the cronjobs

Once that's all configured, there's a `make` target that creates the cronjobs and starts taking photos:

```
make cron
```

By default, this takes 6 photos per minute, one every 10 seconds, but this is configurable simply by editing `conf/photos-per-minute`. For example, setting this to `7` will take one photo every 8-ish seconds. Attempting to take too many photos per minute will cause things to break, so be sensible.

## Pause and unpause

There are two handy `make` targets:

```
make pause
```

which pauses the camera (by deleting all the cronjobs), and

```
make unpause
```

which reinstates the cronjobs and restarts the photography (at the top of the next minute).

## Cleanup

Running

```
make delete
```

will delete _all_ of the photos on the Pi.

## Pull the photos locally

On the container:

```
make pull-photos
```

This pulls the photos from the Pi into `/opt/stills` (where `${STILLS}` is mounted). The `rsync` is running with bandwidth-limiting enabled, because letting it run full-tilt while it's also taking photos seems to overwhelm the Pi, which overheats and shuts down. The amount of limiting is configurable as `BWLIMIT` (in KB/second), so for example to run it unlimited, do

```
BWLIMIT=0 make pull-photos
```

## Make a movie

Once you have all the photos locally, you can make them into a movie:

```
make movie FRAMES_PER_SECOND=25
```

This runs [`ffmpeg`](https://ffmpeg.org/) over the images in `/opt/stills` and dumps a movie at `movies/movie-<timestamp>.mp4`, using these magic spells:

```
-c:v libx264 -vf fps=fps=${FRAMES_PER_SECOND} -pix_fmt yuv420p
```

which may or may not be good, `ffmpeg` is voodoo.

## Incremental pull

To incrementally pull the pictures as they're created, try something like

```
while [ 1 ] ; do make pull-photos ; sleep 2 ; done
```

This will (in theory) eventually catch up. You might want to consider running this inside a `screen` session, too.

## Storage considerations

A full 24 hours of 6-photos-per-minute, in the middle of June (so the minimum amount of all-black photos), runs to about 31GB.
