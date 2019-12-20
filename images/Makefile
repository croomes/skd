# Call from main Makefile (make image)
#
VERSION?=$(shell git describe HEAD --tags)
TAG:=${K8S}$(if $(strip $(VERSION)),-${VERSION})

all: build
build: pull
ifeq ($(OS_NAME),)
	$(error OS_NAME is a required argument)
endif
	@ls os/${OS_NAME} >/dev/null
	@ls kubernetes/${K8S}/images.txt >/dev/null
	cp -f kubernetes/${K8S}/images.txt os/${OS_NAME}/preload_images.txt
	cp -f kubernetes/${K8S}/packages.txt os/${OS_NAME}/preload_packages.txt
	cp -p bin/preload_images.sh os/${OS_NAME}/preload_images.sh
	cp -p bin/ctr129 os/${OS_NAME}/tmp/ctr129
	docker build --build-arg OS_RELEASE --build-arg K8S -t ${DOCKER_USER}/skd-${OS_NAME}${OS_RELEASE}:${TAG} os/${OS_NAME}
	docker tag ${DOCKER_USER}/skd-${OS_NAME}${OS_RELEASE}:${TAG} ${DOCKER_USER}/skd-${OS_NAME}${OS_RELEASE}:${K8S}
ifeq ($(IS_LATEST),true)
	docker tag ${DOCKER_USER}/skd-${OS_NAME}${OS_RELEASE}:${TAG} ${DOCKER_USER}/skd-${OS_NAME}:latest
endif

.PHONY: pull
pull: os/${OS_NAME}/tmp bin/ctr129
	@ls kubernetes/${K8S}/images.txt >/dev/null
	bin/pull_images.sh os/${OS_NAME}/tmp kubernetes/${K8S}/images.txt

os/${OS_NAME}/tmp:
	mkdir os/${OS_NAME}/tmp

bin/ctr129:
	wget -O bin/ctr129 https://github.com/chanwit/containerd/releases/download/v1.2.9-p1/ctr
	chmod +x bin/ctr129

push:
	docker push ${DOCKER_USER}/skd-${OS_NAME}${OS_RELEASE}:${TAG}
	docker push ${DOCKER_USER}/skd-${OS_NAME}${OS_RELEASE}:${OS_RELEASE}
ifeq ($(IS_LATEST),true)
	docker push ${DOCKER_USER}/skd-${OS_NAME}${OS_RELEASE}:latest
endif

distclean:
	rm -f bin/ctr129
	rm -rf os/${OS_NAME}/tmp/

