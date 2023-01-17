#!/usr/bin/env bash


# turn off swap
# Note - if your system configures swap in fstab, comment it out as well
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
# update the node systems
apt update && apt -y full-upgrade
# deps
apt-get install curl apt-transport-https -y
# install kubeadm, kubeclt kubelet
curl -fsSL  https://packages.cloud.google.com/apt/doc/apt-key.gpg| gpg --dearmor -o /etc/apt/trusted.gpg.d/k8s.gpg && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list && apt update && apt-get install wget curl vim git kubelet kubeadm kubectl -y && apt-mark hold kubelet kubeadm kubectl
# Enable kernel modules
modprobe overlay && modprobe br_netfilter
tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
# Install containerd
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay && modprobe br_netfilter
apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/containerd.gpg && curl -s https://download.docker.com/linux/ubuntu/gpg | apt-key add - && echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/containerd.list && apt update && apt install containerd.io -y

mkdir -p /etc/containerd && containerd config default>/etc/containerd/config.toml && exit
systemctl restart containerd && systemctl enable containerd
systemctl enable kubelet && systemctl start kubelet
