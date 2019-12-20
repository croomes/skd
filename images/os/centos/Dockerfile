ARG OS_RELEASE
ARG K8S

FROM centos:${OS_RELEASE}

RUN yum -y install yum-utils device-mapper-persistent-data gnupg2 lvm2


COPY kubernetes.repo /etc/yum.repos.d/kubernetes.repo
ADD  https://download.docker.com/linux/centos/docker-ce.repo /etc/yum.repos.d/docker-ce.repo

# Install common utilities
RUN yum -y update && yum -y install \
		containerd.io \
        iproute \
        iputils \
		libseccomp \
        openssh-server \
        net-tools \
        procps-ng \
		selinux-policy \
        sudo \
        wget

COPY containerd.conf /etc/modules-load.d/containerd.conf

RUN mkdir -p /etcd/containerd && \
    containerd config default > /etc/containerd/config.toml && \
	systemctl enable containerd

COPY preload_images.sh /tmp/preload_images.sh
COPY preload_images.txt /tmp/preload_images.txt
COPY preload_packages.txt /tmp/preload_packages.txt
RUN  chmod +x /tmp/preload_images.sh
COPY tmp/*.tar /tmp/images/
COPY tmp/ctr129 /usr/bin/ctr129
RUN chmod +x /usr/bin/ctr129

RUN yum -y install --disableexcludes kubernetes $(cat /tmp/preload_packages.txt)

# ADD  https://github.com/chanwit/containerd/releases/download/v1.2.9-p1/ctr /usr/bin/ctr129
# RUN  chmod +x /usr/bin/ctr129

WORKDIR /tmp
RUN /usr/bin/containerd & \
	sleep 2 && \
	ctr129 version && \
	bash preload_images.sh && \
	rm -f /etc/docker/daemon.json && \
	rm -rf /tmp/images/ && \
	rm -f /usr/bin/ctr129

# Set the root password to root when logging in through the VM's ttyS0 console
RUN echo root | passwd --stdin root
# Docker sets this automatically, but not containerd.
# It is required when running kubeadm.
RUN echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
RUN sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

RUN systemctl enable kubelet.service
# RUN kubeadm config images pull --cri-socket /run/containerd/containerd.sock

