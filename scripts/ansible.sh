#!/bin/bash
#
# Setup Ansible 

yum install -y epel-release --nogpgcheck
yum module install -y python36
yum install -y expect
pip3 install --upgrade pip
pip3 install ansible==$VERSION
####### BEGIN: Generate public and private key pairs - id_rsa, id_rsa.pub
mkdir -pv /root/.ssh
ssh-keygen -N "" -f /root/.ssh/id_rsa