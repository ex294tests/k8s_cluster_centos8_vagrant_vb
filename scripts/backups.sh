#!/bin/bash
# tool to create snapshots

curl -LO https://github.com/etcd-io/etcd/releases/download/v3.5.6/etcd-v3.5.6-linux-amd64.tar.gz
tar xvzf etcd-v3.5.6-linux-amd64.tar.gz
export PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/home/vagrant/etcd-v3.5.6-linux-amd64:/home/vagrant/etcd-v3.5.6-linux-amd64
cert_path=/etc/kubernetes/pki/etcd/
export ETCDCTL_API=3
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd//ca.crt
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd//server.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd//server.key
export ETCDCTL_ENDPOINTS=https://10.0.0.11:2379
etcdctl endpoint health

