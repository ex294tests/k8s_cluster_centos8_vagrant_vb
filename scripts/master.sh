#!/bin/bash
#
# Setup for Control Plane (Master) servers

# set -euxo pipefail

NODENAME=$(hostname -s)

#sed -i 's/^disabled_plugins/enabled_plugins/' /etc/containerd/config.toml
rm -f /etc/containerd/config.toml
systemctl restart containerd


sudo kubeadm config images pull

echo "Preflight Check Passed: Downloaded All Required Images"


#clusterIP = $((CONTROL_IP + 1))
#echo "1 $CONTROL_IP"
#echo "2 $clusterIP"



#sudo kubeadm init --apiserver-advertise-address=$CONTROL_IP --apiserver-cert-extra-sans=$CONTROL_IP --pod-network-cidr=$POD_CIDR --service-cidr=$SERVICE_CIDR --node-name "$NODENAME" --ignore-preflight-errors Swap --upload-certs | tee -a /tmp/kubeadminit.log

 kubeadm init --control-plane-endpoint=$CONTROL_IP --apiserver-advertise-address=$CONTROL_IP --apiserver-cert-extra-sans=$CONTROL_IP --pod-network-cidr=172.16.1.0/16 --service-cidr=172.17.1.0/18 --node-name "$NODENAME" --ignore-preflight-errors Swap --upload-certs | tee -a /tmp/kubeadminit.log


#export KUBECONFIG=/etc/kubernetes/admin.conf 

sudo mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Save Configs to shared /Vagrant location

# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.



config_path="/vagrant/configs"

if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi

sudo cp -i /etc/kubernetes/admin.conf $config_path/config
#kubeadm token create --print-join-command > $config_path/join.sh
sudo tail -n2 /tmp/kubeadminit.log > $config_path/join.sh
sudo chmod +x $config_path/join.sh


# save certkey for extra masters
#kubeadm init phase upload-certs --upload-certs | tail -n1 > $config_path/certkey
# generate script for masters to join the cluster
#cat $config_path/join.sh | tr '\n' ' '|tee -a $config_path/extramaster.sh 2>&1 > /dev/null
#echo '--control-plane --certificate-key' | tr '\n' ' '|tee -a $config_path/extramaster.sh 2>&1 > /dev/null
#cat $config_path/certkey | tr '\n' ' '|tee -a $config_path/extramaster.sh 2>&1 > /dev/null

sudo cat /tmp/kubeadminit.log |grep "certificate-key" -B2|head -n3 > $config_path/extramaster.sh
sudo chmod +x $config_path/extramaster.sh



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

kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml

# kubectl apply -f https://drive.google.com/file/d/1IB7b5CzOAnMyedq1mJhTH9dIMEIdJkQm/view?usp=sharing


# copy .vimrc and .bashrc
cp -f /vagrant/cka/{.vimrc,.bashrc} /root

# copy cka yaml files
#sudo mkdir -p /root/cka
#sudo cp -f /vagrant/cka/*.yaml /root/cka
