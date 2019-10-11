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

# Script full path. The following is taken from
# https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself/4774063
SCRIPT_PATH="$( cd $(dirname $0) ; pwd -P )"

$($SCRIPT_PATH/k8s-install-common.sh)

echo ""
echo "====================================================================================================="
echo -n "[INFO] If all finished with success continue with the installation on the k8s master. [y/N] "
read REPLY
echo "====================================================================================================="
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
   exit
fi

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

echo -n "[!] Install Flannel network? [y/n] "
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
echo "   1. run k8s-install_node.sh
echo "   2. run kubeadm join ... (see print-outs after kubeadm init on the master)"
echo "====================================================================================================="