#!/usr/bin/env bash
#
# Copyright (c) 2017 - 2019 Karlsruhe Institute of Technology - Steinbuch Centre for Computing
# This code is distributed under the MIT License
# Please, see the LICENSE file
#
# Bash script to install Kubernetes master (k8s cluster: 1 master + several worker nodes)
# - written for RHEL7 / CentOS7
# - makes updates
# - installs Docker from docker.com (docker-ce)
# - installs kubernetes packages: kubeadm, kubelet, kubectl
# - installs Flannel network

### A FEW CONFIGS ###
K8S_VER="1.14.1-0"
K8S_POD_NETWORK="10.244.0.0/16"
###

echo "[INFO] Update yum"
sudo yum update

echo -n "[!] Swtich off swap? [y/n] "
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
echo -n "[!] (Re-)Install Docker (previous installation will be removed!)? [y/n]?"
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

echo "[INFO] Load ip_tables"
sudo modprobe ip_tables
echo -n "[!] Enable bridge-nf-call-iptables (needed)? [y/n] "
read REPLY
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
   sudo sysctl net.bridge.bridge-nf-call-iptables=1
fi

echo "[INFO] Checking bridge-nf-call-iptables (has to be 1)"
cat /proc/sys/net/bridge/bridge-nf-call-iptables

echo ""
echo "[INFO] Check Docker cgroup"
echo "  Important for KUBELET_CGROUP_ARGS=--cgroup-driver=systemd"
echo "  in /etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
sudo docker info |grep -i cgroup

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

echo -n "[!] Init master? [y/n] "
read REPLY
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
   sudo kubeadm init --pod-network-cidr=$K8S_POD_NETWORK
fi

echo -n "[!] Copy admin.conf to $USER account? [y/n] "
read REPLY
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
fi

echo -n "[!] Install Flannel network? (y/n)"
read REPLY
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
   echo "..[INFO] Installing Flannel"
   sudo bash -c 'export KUBECONFIG=/etc/kubernetes/admin.conf && \
   kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml'
fi

echo "[INFO] Checking pods of kubernetes"
kubectl get pods --all-namespaces

echo ""
echo "====================================================================================================="
echo "[INFO] If all finished with success, go to a node and install k8s and join the node with the cluster:"
echo "   1. Check that swap is off  (cat /proc/swaps). If not: sudo swapoff -a"
echo "   2. Check that 'sudo docker info |grep -i cgroup' returns systemd, if not edit:"
echo "      /usr/lib/systemd/system/docker.service :  ExecStart=/usr/bin/dockerd  --exec-opt native.cgroupdriver=systemd"
echo "   3. sudo yum install -y kubelet-$K8S_VER kubeadm-$K8S_VER kubectl-$K8S_VER"
echo "   4. run kubeadm join ... (see previous print-outs after kubeadm init on the master)"
echo "====================================================================================================="