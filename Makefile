IS_MAC := $(shell uname -a | grep 'Darwin')
ifneq ($(IS_MAC),)
	include make/Makefile.mac
endif

IS_DOCKER := $(shell uname -a | grep '64 GNU/Linux')
ifneq ($(IS_DOCKER),)
	include make/Makefile.docker
endif

IS_PI := $(shell uname -a | grep 'armv.* GNU/Linux')
ifneq ($(IS_PI),)
	include make/Makefile.pi
endif

build:  ## build the container
	docker build \
		--build-arg PROJECT=${PROJECT} \
		--tag ${ID} .

ci: build
	docker run \
		--name ${PROJECT} \
		--hostname ${PROJECT} \
		--env PROJECT=${PROJECT} \
		--rm \
		${ID} \
		test

guard-%:
	@if [ -z "${${*}}" ] ; \
	then \
			echo "You must provide the ${*} variable" ; \
			exit 1 ; \
	fi

# absolute voodoo from @rgarner
help:  ## show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' ${MAKEFILE_LIST} | sed "s/.*:\(.*:.*\)/\1/" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
