ME = $(shell git config --global user.name)
ifeq ($(ME),)  # this will resolve to empty-string in CI
	ME := fakeperson
endif

PROJECT = $(shell basename $(shell pwd))

ID = ${ME}/${PROJECT}

PI = lapsecam.local
BWLIMIT ?= 1000

### container only

# default to formatting amd linting
default: format lint test cleanup freeze  ## (container only) `format`, `lint`, `test`, `cleanup`, `freeze`

format: black isort  ## (container only) run the formatters

black:
	python -m black .

isort:
	python -m isort .

lint:  ## (container only) run the linters
	python -m pylama

test:  ## (container only) run the tests
	PYTHONDONTWRITEBYTECODE=1 \
		python -m pytest \
		--random-order \
		--verbose \
		--capture no \
		--failed-first \
		--exitfirst

cleanup:  ## (container only) clean out cache cruft
	@rm -fr $$(find . -name __pycache__)
	@rm -fr $$(find . -name .pytest_cache)

freeze:  ## (container only) freeze the pip versions
	python -m pip freeze > requirements.txt

push-code:  ## (container only) push code to the pi
	rsync --archive \
		  --verbose \
		  --delete \
		  --exclude .git \
		  --exclude movies \
		  . \
		  pi@${PI}:${PROJECT}

pull-photos:  ## (container only) rsync the photos off the pi
# https://serverfault.com/a/98750
	while ! rsync --archive \
				  --verbose \
				  --bwlimit=${BWLIMIT} \
				  pi@lapsecam.local:photos/ /opt/stills/ ; do \
				  	sleep 5 ; \
				  done


movie:  ## (container only) make a movie
	bash /opt/${PROJECT}/scripts/make-movie.sh

### laptop only

build:  ## (laptop only) build the container
	docker build \
		--build-arg PROJECT=${PROJECT} \
		--tag ${ID} .

run: guard-STILLS  ## (laptop only) run the container
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

ci:
	docker run \
		--name ${PROJECT} \
		--hostname ${PROJECT} \
		--env PROJECT=${PROJECT} \
		--rm \
		${ID} \
		test

### pi only

setup: install aim  ## (pi only) install dependencies and aim the camera

install: apt-installs python-installs  ## (pi only) install the dependencies

apt-installs:
	sudo apt-get update
	sudo apt-get install \
		--no-install-recommends \
		--yes \
		python3-pip

python-installs:
	python -m pip install -r requirements-pi.txt

cron:  ## (pi only) setup the cronjobs
	sudo python scripts/build_cron.py

pause:  ## (pi only) pause photography
	sudo rm /etc/cron.d/${PROJECT}

unpause: cron  ## (pi only) restart photography

aim:  ## (pi only) stream video from the camera
	@curl https://raw.githubusercontent.com/RuiSantosdotme/Random-Nerd-Tutorials/master/Projects/rpi_camera_surveillance_system.py -o /tmp/aimcam.py
	@echo
	@echo "Go to"
	@echo
	@echo "    http://$(shell hostname).local:8000"
	@echo
	@echo "to aim your camera (ctrl-C to stop)"
	@echo
	@python /tmp/aimcam.py

clean:  ## (pi only) delete all the photos
	rm -fr /home/pi/photos/

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
