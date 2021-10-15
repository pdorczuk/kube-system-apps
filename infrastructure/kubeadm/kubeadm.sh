#!/usr/bin/env bash

# Globals
GREEN="\033[0;32m"
PURPLE="\033[0;35m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color
OK="${GREEN}OK${NC}\r\n"


printf "${PURPLE}Destroy the cluster..."
sudo kubeadm reset --force > /dev/null 2>&1
printf "${OK}"

printf "${PURPLE}Clean up iptables..."
sudo iptables -F > /dev/null 2>&1
sudo iptables -t nat -F > /dev/null 2>&1
sudo iptables -t mangle -F > /dev/null 2>&1
sudo iptables -X > /dev/null 2>&1
printf "${OK}"

printf "${PURPLE}Remove kubectl config file..."
rm -rf $HOME/.kube/config > /dev/null 2>&1
printf "${OK}"

# Initialize the cluster using the config file that includes OIDC configuration
printf "${PURPLE}Create cluster using Kubeadm..."
sudo kubeadm init --config=./kubeadm-config.yaml > /dev/null 2>&1
printf "${OK}"

# Copy the root credentials file into my home directory.
printf "${PURPLE}Copy kubectl config files..."
mkdir -p $HOME/.kube > /dev/null 2>&1
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config > /dev/null 2>&1
sudo chown $(id -u):$(id -g) $HOME/.kube/config > /dev/null 2>&1
printf "${OK}"

# Allow pods to run on master
printf "${PURPLE}Taint the node to allow pod scheduling..."
kubectl taint nodes --all node-role.kubernetes.io/master- > /dev/null 2>&1
printf "${OK}"

# Install Calico
printf "${PURPLE}Install Calico networking..."
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml > /dev/null 2>&1
kubectl create -f ./calico-config.yaml > /dev/null 2>&1
kubectl -n kube-system wait --for=condition=ready pod kube-scheduler-mothership
printf "${OK}"
