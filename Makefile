# Tunable image params
DOCKER_USER	?= croomes
OS_NAME		?= centos
OS_RELEASE	?= 7
K8S			?= 1.17.0
IS_LATEST	?=

IGNITE_IMAGE ?= $(DOCKER_USER)/skd-$(OS_NAME)$(OS_RELEASE):$(K8S)
IGNITE_KERNEL ?= TODO

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

cluster: .cluster
.cluster: .init .join

.init: .master
	sudo ignite exec master-0 "kubeadm version"
	sudo ignite exec master-0 "kubeadm init --config /kubeadm.yaml --upload-certs"
	@touch .init

.master: run/config.yaml
	sudo ignite run $(IGNITE_IMAGE) --cpus 2 --memory 1GB --ssh \
		--copy-files $(ROOT_DIR)/run/config.yaml:/kubeadm.yaml \
		--copy-files $(ROOT_DIR)/run/pki/ca.crt:/etc/kubernetes/pki/ca.crt \
		--copy-files $(ROOT_DIR)/run/pki/ca.key:/etc/kubernetes/pki/ca.key \
		--name master-0
	@touch .cluster

.workers:
	for i in {1..3}; do \
		sudo ignite run $(IGNITE_IMAGE) --cpus 2 --memory 1GB --ssh \
			--name worker-$$i; \
	done
	@touch .workers

.join: .workers .admin
	source .admin
	for i in {1..3}; do \
		sudo ignite exec worker-$$i "echo kubeadm join $${MASTER_IP}:6443 \
			--token $${TOKEN} \
			--discovery-token-ca-cert-hash sha256:$${CA_HASH} \
			--certificate-key $${CERT_KEY} \
			--control-plane"; \
	done
	@touch .join


image:
	cd images && DOCKER_USER=$(DOCKER_USER) OS_NAME=$(OS_NAME) OS_RELEASE=$(OS_RELEASE) K8S=$(K8S) IS_LATEST=$(IS_LATEST) make build

# Dependencies
SHELL = bash
.ONESHELL:

run/config.yaml: run run/pki .admin
	K8S=$(K8S) ./gen_config.sh .admin run/config.yaml

run/pki:
	docker run -i --rm -v $(ROOT_DIR)/run:/etc/kubernetes $(IGNITE_IMAGE) \
    	kubeadm init phase certs ca

run/admin.conf:
	# docker run -i --rm --net host -v $(ROOT_DIR)/run:/etc/kubernetes $(IGNITE_IMAGE)
	docker run -i --rm -v $(ROOT_DIR)/run:/etc/kubernetes $(IGNITE_IMAGE) \
    	kubeadm init phase kubeconfig admin

.admin: run/admin.conf
	echo MASTER_IP=$(shell sudo grep server run/admin.conf | grep -o -e "[0-9\.]*" | head -1) > $@
	echo TOKEN=$(shell docker run -i --rm -v $(ROOT_DIR)/run:/etc/kubernetes $(IGNITE_IMAGE) kubeadm token generate) >> $@
	echo CERT_KEY=$(shell docker run -i --rm -v $(ROOT_DIR)/run:/etc/kubernetes $(IGNITE_IMAGE) kubeadm alpha certs certificate-key) >> $@
	echo CA_HASH=$(shell openssl x509 -pubkey -in run/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //') >> $@

run:
	mkdir -p run

clean: clean-cluster

clean-cluster: clean-workers clean-master
	rm -f .cluster

clean-master:
	sudo ignite rm -f master-0
	sudo rm -rf run/
	rm -rf .master .init

clean-workers:
	for i in {1..3}; do \
		sudo ignite rm -f worker-$$i; \
	done
	rm -f .workers .join
