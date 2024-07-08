#!/bin/bash
#
# Setup for Node servers

#set -euxo pipefail

config_path="/vagrant/configs"

sed -i 's/^disabled_plugins/enabled_plugins/' /etc/containerd/config.toml
# sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd

/bin/bash $config_path/join.sh -v

sudo cp -i $config_path/config /etc/kubernetes/admin.conf

sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
NODENAME=$(hostname -s)
kubectl label node $(hostname -s) node-role.kubernetes.io/worker=worker
EOF
