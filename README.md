Bash scripts to install Kubernetes cluster
=========================================

Set of bash scripts for RHEL7/CentOS7 to install a simple Kubernetes cluster (one master and a few nodes).

* k8s-install-common.sh : common steps for either master or a worker node: installs necessary packages, adds docker.com repository, installs Docker, installs kubelet, kubeadm, kubectl
* k8s-install_master.sh : continues installation for the master: kubeadm init, installs Flannel
* k8s-install_node.sh   : continues installation for a worker node (as of now, simple calls k8s-install-common.sh)

Once the repository cloned, do not forget to make scripts executable, "chmod +x *.sh"

Run k8s-install_master.sh on the master
Run k8s-install_node      on a node

ToDo
----

at least partially move the scripts to ansible.


V. Kozlov
