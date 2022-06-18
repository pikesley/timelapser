PROJECT = $(shell basename $(shell pwd))
ME=$(shell git config --global user.name)
ID = ${ME}/${PROJECT}
PHOTOS_PER_MINUTE=4
PI=lapsecam.local
BWLIMIT=1000

# default to formatting amd linting
default: format lint freeze

build:
	docker build \
		--build-arg PROJECT=${PROJECT} \
		--tag ${ID} .

run: guard-STILLS
	docker run \
		--name ${PROJECT} \
		--hostname ${PROJECT} \
		--volume $(shell pwd):/opt/${PROJECT} \
		--volume ${STILLS}:/opt/stills \
		--volume ${HOME}/.ssh:/root/.ssh \
		--env PROJECT=${PROJECT} \
		--interactive \
		--tty \
		--rm \
		${ID} \
		bash

### container only

format: black isort

black:
	python -m black .

isort:
	python -m isort .

lint:
	python -m pylama

freeze:
	python -m pip freeze > requirements.txt

push-code:
	rsync --archive \
		  --verbose \
		  --delete \
		  --exclude .git \
		  --exclude movies \
		  . \
		  pi@${PI}:${PROJECT}

pull-photos:
	rsync -av --bwlimit=${BWLIMIT} pi@${PI}:photos/ /opt/stills

movie:
	bash /opt/${PROJECT}/scripts/make-movie.sh

### pi only

setup: install aim

install: apt-installs python-installs

apt-installs:
	sudo apt-get update
	sudo apt-get install \
		--no-install-recommends \
		--yes \
		python3-pip

python-installs:
	python -m pip install -r requirements-pi.txt

cron:
	sudo python scripts/build_cron.py ${PHOTOS_PER_MINUTE}

aim:
	@curl https://raw.githubusercontent.com/RuiSantosdotme/Random-Nerd-Tutorials/master/Projects/rpi_camera_surveillance_system.py -o /tmp/aimcam.py
	@echo
	@echo "Go to"
	@echo
	@echo "    http://$(shell hostname).local:8000"
	@echo
	@echo "to aim your camera (ctrl-C to stop)"
	@echo
	@python /tmp/aimcam.py

clean:
	rm -fr /home/pi/photos/

### generic

guard-%:
	@if [ -z "${${*}}" ] ; \
	then \
			echo "You must provide the ${*} variable" ; \
			exit 1 ; \
	fi
