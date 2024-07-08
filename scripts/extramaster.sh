#!/bin/bash
#
# Setup for Control Plane (Master) servers

# set -euxo pipefail


#sed -i 's/^disabled_plugins/enabled_plugins/' /etc/containerd/config.toml
sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd



sudo kubeadm config images pull

echo "Preflight Check Passed: Downloaded All Required Images"


config_path="/vagrant/configs"

# add additional control plane to the k8s cluster
$config_path/extramaster.sh

export KUBECONFIG=/etc/kubernetes/admin.conf 

#mkdir -p "$HOME"/.kube
#sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
#sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config


# Install Calico Network Plugin

curl https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/calico.yaml -O
#curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml -O

kubectl apply -f calico.yaml

sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF

# Install Metrics Server

# kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml

# kubectl apply -f https://drive.google.com/file/d/1IB7b5CzOAnMyedq1mJhTH9dIMEIdJkQm/view?usp=sharing


# copy .vimrc and .bashrc
cp -f /vagrant/cka/{.vimrc,.bashrc} /root

