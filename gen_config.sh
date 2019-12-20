#!/usr/bin/env bash
#
# gen_config.sh <envvars.sh> <destfile>
#
# Run from Makefile
#

source $1

[ -z $K8S ] && exit 1
[ -z $TOKEN ] && exit 1
[ -z $CERT_KEY ] && exit 1
[ -z $MASTER_IP ] && exit 1

cat <<- EOF > $2
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
- token: "${TOKEN}"
certificateKey: "${CERT_KEY}"
nodeRegistration:
  criSocket: /run/containerd/containerd.sock
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v${K8S}
apiServer:
  certSANs:
  - "${MASTER_IP}"
EOF