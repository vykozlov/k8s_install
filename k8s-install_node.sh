#!/usr/bin/env bash
#
# Copyright (c) 2017 - 2019 Karlsruhe Institute of Technology - Steinbuch Centre for Computing
# This code is distributed under the MIT License
# Please, see the LICENSE file
#
# Bash script to install Kubernetes node (k8s cluster: 1 master + several worker nodes)
# - written for RHEL7 / CentOS7
# - makes updates
# - installs Docker from docker.com (docker-ce)
# - installs kubernetes packages: kubeadm, kubelet, kubectl

# Script full path. The following is taken from
# https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself/4774063
SCRIPT_PATH="$( cd $(dirname $0) ; pwd -P )"

$($SCRIPT_PATH/k8s-install-common.sh)

echo ""
echo "====================================================================================================="
echo "[INFO] If all finished with success:"
echo "   - run kubeadm join ... (see print-outs after kubeadm init on the master)"
echo "====================================================================================================="