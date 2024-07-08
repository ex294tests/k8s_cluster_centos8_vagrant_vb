#!/bin/bash
#
# Setup for Node servers

#set -euxo pipefail


cd /etc/yum.repos.d/
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
cd
echo N | dnf update
yum install -y nfs-utils
systemctl enable --now {nfs-server,rpcbind,firewalld}
systemctl start {nfs-server,rpcbind,firewalld}

mkdir -p $NFS_DIR
echo "${NFS_DIR} ${SUBNET}0/24(rw,insecure,sync,no_subtree_check,no_root_squash)" > /etc/exports
# *(rw,insecure,sync,no_subtree_check,no_root_squash)
chown nobody:nobody $NFS_DIR
chmod 775 $NFS_DIR
exportfs -rv

firewall-cmd --permanent --add-service={nfs,rpc-bind,mountd}
firewall-cmd --reload
showmount -e localhost

# SELINUX
setsebool -P nfs_export_all_rw 1
setsebool -P nfs_export_all_ro 1
semanage fcontext -a -t public_content_rw_t "NFS_DIR(/.*)?"
restorecon -R $NFS_DIR
