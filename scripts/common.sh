#!/bin/bash
#
# Common setup for all servers (Control Plane and Nodes)

#set -euxo pipefail

# Variable Declaration


setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -P ""


# DNS Setting
if [ ! -d /etc/systemd/resolved.conf.d ]; then
	sudo mkdir /etc/systemd/resolved.conf.d/
fi
#cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dns_servers.conf
#[Resolve]
#DNS=${DNS_SERVERS}
#EOF


cat <<EOF | sudo tee /etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 127.0.0.53
options edns0 trust-ad
search .
EOF


sudo systemctl restart systemd-resolved



# disable firewalld
systemctl stop firewalld
systemctl disable firewalld


# Permanently disable swapping
sed -e '/swap/ s/^#*/#/g' -i /etc/fstab
# disable swap
sudo swapoff -a
# keeps the swaf off during reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true

#sudo echo N | dnf update


# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system



cd /etc/yum.repos.d/
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
cd
echo N | dnf update
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
#dnf config-manager --add-repo=https://download.docker.com/linux/rhel/docker-ce.repo
 #dnf install -y https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
 dnf install -y https://download.docker.com/linux/centos/8/x86_64/stable/Packages/containerd.io-1.6.9-3.1.el8.x86_64.rpm
#dnf install -y https://download.docker.com/linux/rhel/8/x86_64/stable/Packages/containerd.io-1.6.33-3.1.el8.x86_64.rpm
echo N | dnf update
dnf install -y iproute-tc jq sshpass nc 
dnf install -y docker-ce
systemctl enable docker
systemctl start docker
 
# Create /etc/docker directory
mkdir -p /etc/docker

# Setup daemon
cat <<EOF | sudo tee /etc/docker/daemon.json > /dev/null
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF



 
 
 

# create repo with k8s version in settings.yml
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION_SHORT/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION_SHORT/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF


local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
${ENVIRONMENT}
EOF




sudo echo N | dnf update
# sudo dnf install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"

sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet
systemctl start kubelet
#systemctl status kubelet


# Add Google NTP Server
sed -i '/^pool/c\pool time.google.com iburst' /etc/chrony.conf
# Set timezone to Asia/Colombo
timedatectl set-timezone Europe/Dublin
# Enable NTP time synchronization
timedatectl set-ntp true
# Start and enable chronyd service
systemctl enable --now chronyd
# Check if the chronyd service is running
systemctl status chronyd

# Disable IPv6 on eth1 interface
# nmcli connection modify eth1 ipv6.method ignore


