#!/bin/bash

echo StrictHostKeyChecking=no > $HOME/.ssh/config
chmod 0600 $HOME/.ssh/config

yum install -y ansible-collection-community-general vim-enhanced sshpass

ansible -u root -b -k -m user -a "name=automation comment='Automation user' generate_ssh_key=yes shell=/bin/bash groups=wheel password={{ 'devops' | password_hash('sha512') }}" -i inventory localhost:all 

ansible -u root -b -k -m authorized_key -a "user=automation state=present key=\"{{ lookup('file', '/home/automation/.ssh/id_rsa.pub') }}\" " -i inventory all

ansible -u root -b -k -m copy -a "content='automation ALL=(root) NOPASSWD:ALL' dest=/etc/sudoers.d/automation" -i inventory all

ansible -u root -b -k -m lineinfile -a "path=/home/automation/.ssh/config line=StrictHostKeyChecking=no owner=automation group=automation  mode='0600' create=yes" -i inventory all

echo  "set ai nu cuc cul et ts=2 sw=2" > $HOME/.vimrc

echo "
alias ap='ansible-playbook '
alias aps='ansible-playbook --syntax-check '
alias apc='ansible-playbook --check '

# function to look up examples only using keywords, ie 'aex user'
function aex(){
   ansible-doc $1|sed -n -e '/EXAM/,/RET/ p'
}
" >>  $HOME/.bashrc
source  $HOME/.bashrc
source  $HOME/.vimrc
