ME = $(shell git config --global user.name)
ifeq ($(ME),)  # this will resolve to empty-string in CI
	ME := fakeperson
endif

PROJECT = $(shell basename $(shell pwd))

ID = ${ME}/${PROJECT}

PI = lapsecam.local
BWLIMIT ?= 1000
PHOTOS_DIR = /home/pi/photos

default: help

### container only

all: docker-only format lint test clean freeze  ## (container only) `format`, `lint`, `test`, `clean`, `freeze`

format: docker-only black isort  ## (container only) run the formatters

black:
	python -m black .

isort:
	python -m isort .

lint: docker-only  ## (container only) run the linters
	python -m pylama

test: docker-only  ## (container only) run the tests
	PYTHONDONTWRITEBYTECODE=1 \
		python -m pytest \
		--random-order \
		--verbose \
		--capture no \
		--failed-first \
		--exitfirst

clean: docker-only  ## (container only) clean out cache cruft
	@rm -fr $$(find . -name __pycache__)
	@rm -fr $$(find . -name .pytest_cache)

freeze: docker-only  ## (container only) freeze the pip versions
	python -m pip freeze > requirements.txt

send-key: docker-only
	ssh-copy-id -i /root/.ssh/id_rsa.pub pi@${PI}

push-code: docker-only  ## (container only) push code to the pi
	rsync --archive \
		  --verbose \
		  --delete \
		  --exclude .git \
		  --exclude movies \
		  . \
		  pi@${PI}:${PROJECT}

pull-photos: docker-only  ## (container only) rsync the photos off the pi
# https://serverfault.com/a/98750
	while ! rsync --archive \
				  --verbose \
				  --bwlimit=${BWLIMIT} \
				  pi@lapsecam.local:photos/ /opt/stills/ ; do \
				  	sleep 5 ; \
				  done


movie: docker-only  ## (container only) make a movie
	bash /opt/${PROJECT}/scripts/make-movie.sh

### laptop only

build:  ## (laptop only) build the container
	docker build \
		--build-arg PROJECT=${PROJECT} \
		--tag ${ID} .

run: laptop-only guard-STILLS  ## (laptop only) run the container
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


### pi only

setup: pi-only install make-photo-dir aim  ## (pi only) install dependencies and aim the camera

install: pi-only apt-installs python-installs  ## (pi only) install the dependencies

apt-installs: pi-only
	sudo apt-get update
	sudo apt-get install \
		--no-install-recommends \
		--yes \
		python3-pip \
		git

python-installs: pi-only
	python -m pip install -r requirements-pi.txt

make-photo-dir: pi-only
	mkdir -p ${PHOTOS_DIR}/

cron: pi-only  ## (pi only) setup the cronjobs
	sudo python scripts/build_cron.py

pause: pi-only  ## (pi only) pause photography
	sudo rm /etc/cron.d/${PROJECT}

unpause: pi-only cron  ## (pi only) restart photography

aim: pi-only  ## (pi only) stream video from the camera
	@curl https://raw.githubusercontent.com/RuiSantosdotme/Random-Nerd-Tutorials/master/Projects/rpi_camera_surveillance_system.py -o /tmp/aimcam.py
	@echo
	@echo "Go to"
	@echo
	@echo "    http://$(shell hostname).local:8000"
	@echo
	@echo "to aim your camera (ctrl-C to stop)"
	@echo
	@python /tmp/aimcam.py

delete: pi-only  ## (pi only) delete all the photos
	rm -fr ${PHOTOS_DIR}/*

watch: pi-only  ## (pi only) watch the photos directory
	watch "ls -1 ${PHOTOS_DIR}/ | tail -10"

### ci only

ci: build
	docker run \
		--name ${PROJECT} \
		--hostname ${PROJECT} \
		--env PROJECT=${PROJECT} \
		--rm \
		${ID} \
		test

### generic

guard-%:
	@if [ -z "${${*}}" ] ; \
	then \
			echo "You must provide the ${*} variable" ; \
			exit 1 ; \
	fi

# absolute voodoo from @rgarner
help:  ## show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# guardrails

docker-only:
	@if ! [ "$(shell uname -a | grep '64 GNU/Linux')" ] ;\
	then \
			echo "This target can only be run inside the container" ;\
			exit 1 ;\
	fi

laptop-only:
	@if ! [ "$(shell uname -a | grep 'Darwin')" ] ;\
	then \
			echo "This target can only be run on the laptop" ;\
			exit 1 ;\
	fi

pi-only:
	@if ! [ "$(shell uname -a | grep 'armv.* GNU/Linux')" ] ;\
	then \
			echo "This target can only be run on the Pi" ;\
			exit 1 ;\
	fi
