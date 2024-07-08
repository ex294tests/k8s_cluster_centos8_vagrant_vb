Create your lab by using the Vagrantfile
The ansible host will be the NFS server 1 (K9S_nfs01)
Run playbook k8snodes_upgrade.yml against one of the nodes to upgrade, i.e.: **ansible-playbook k8snodes_upgrade.yml --extra-vars "target=node02"**
