#!/usr/bin/env bash
#
# Copyright (c) 2017 - 2019 Karlsruhe Institute of Technology - Steinbuch Centre for Computing
# This code is distributed under the MIT License
# Please, see the LICENSE file
#
# Bash script to execute common steps / install common packages for either 
# Kubernetes master or node (k8s cluster: 1 master + several worker nodes)
# - written for RHEL7 / CentOS7
# - makes updates
# - installs Docker from docker.com (docker-ce)
# - installs kubernetes packages: kubeadm, kubelet, kubectl

### A FEW CONFIGS ###
K8S_VER="1.14.1-0"
K8S_POD_NETWORK="10.244.0.0/16"
###

echo "[INFO] Update yum"
sudo yum update

echo -n "[!] Switch off swap? [y/N] "
read REPLY
echo "" # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo swapoff -a
    echo "..[INFO] to make it persistent, comment swap in /etc/fstab"
fi

echo""
echo "[INFO] Installing additional packages: yum-utils, device-mapper-persistent-data lvm2"
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

echo ""
echo "[INFO] Enabling rhel-7-server-extras-rpms"
sudo subscription-manager repos --enable=rhel-7-server-extras-rpms
echo -n "[!] (Re-)Install Docker (previous installation will be removed!)? [y/N] "
read REPLY
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
   echo "..[INFO] We will remove old Docker and install one from docker.com"
   sudo yum remove docker \
                   docker-client \
                   docker-client-latest \
                   docker-common \
                   docker-latest \
                   docker-latest-logrotate \
                   docker-logrotate \
                   docker-selinux \
                   docker-engine-selinux \
                   docker-engine

   sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
   sudo yum install container-selinux
   sudo yum install docker-ce
   sudo systemctl enable docker && sudo systemctl start docker
fi

echo ""
echo "[INFO] Check Docker cgroup"
echo "  Important for --cgroup-driver=systemd in /var/lib/kubelet/kubeadm-flags.env"
echo "  systemd has to be also in /usr/lib/systemd/system/docker.service"
DOCKER_CGROUP=$(sudo docker info |grep -i cgroup)
if [[ $DOCKER_CGROUP != *"systemd"* ]]; then
   echo "..[(Strong) WARNING!] Docker's CGROUP is NOT configured for 'systemd'!"
   echo "  You are advised to edit /usr/lib/systemd/system/docker.service and add"
   echo "  '--exec-opt native.cgroupdriver=systemd' in ExecStart "
   echo -n "  [!] Start nano editor to edit the file? [y/N] "
   read REPLY
   echo ""
   if [[ $REPLY =~ ^[Yy]$ ]]; then
      sudo yum install -y nano && sudo nano /usr/lib/systemd/system/docker.service
   fi
fi

echo "[INFO] Load ip_tables"
sudo modprobe ip_tables
echo -n "[!] Enable bridge-nf-call-iptables (needed)? [y/N] "
read REPLY
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
   sudo sysctl net.bridge.bridge-nf-call-iptables=1
fi

echo "[INFO] Checking bridge-nf-call-iptables (has to be 1)"
cat /proc/sys/net/bridge/bridge-nf-call-iptables

echo ""
echo "[INFO] Install kubelet, kubadm, kubectl"
# become root for the next action
sudo bash -c 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF'

sudo setenforce 0
sudo yum install -y kubelet-$K8S_VER kubeadm-$K8S_VER kubectl-$K8S_VER
sudo systemctl enable kubelet && sudo systemctl start kubelet
