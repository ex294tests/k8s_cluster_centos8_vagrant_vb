

require "yaml"
vagrant_root = File.dirname(File.expand_path(__FILE__))
settings = YAML.load_file "#{vagrant_root}/settings.yaml"


# controllers (_C) start at IP .10
# nodes (_N) start at IP .20
# nfs (_NFS) start at IP .50

IP_SECTIONS_C = settings["network"]["control_ip"].match(/^([0-9.]+\.)([^.]+)$/)
IP_SECTIONS_N = settings["network"]["node_ip"].match(/^([0-9.]+\.)([^.]+)$/)
IP_SECTIONS_NFS = settings["network"]["nfs_ip"].match(/^([0-9.]+\.)([^.]+)$/)

# First 3 octets including the trailing dot:
IP_NW_C = IP_SECTIONS_C.captures[0]
IP_NW_N = IP_SECTIONS_N.captures[0]
IP_NW_NFS = IP_SECTIONS_NFS.captures[0]

# Last octet excluding all dots:
IP_START_C = Integer(IP_SECTIONS_C.captures[1])
IP_START_N = Integer(IP_SECTIONS_N.captures[1])
IP_START_NFS = Integer(IP_SECTIONS_NFS.captures[1])

NUM_WORKER_NODES = settings["nodes"]["workers"]["count"]
NUM_CONTROL_NODES = settings["nodes"]["control"]["count"]
NUM_NFS_SERVERS = settings["nfs"]["count"]
DOMAIN = settings["network"]["domain"]

CONTR_NAME = settings["nodes"]["control"]["name"]
NODE_NAME = settings["nodes"]["workers"]["name"]
NFS_NAME = settings["nfs"]["name"]

NFS_STORAGE_SIZE = settings["nfs"]["storage_size"]

LAB_NAME = 'K8S_'

USER = ENV['USER'] = 'root'
USER_HOME = ENV['USER_HOME'] = '/root'
USER_PASSWORD = ENV['USER_PASSWORD'] = 'root'
SSH_PATH = #{USER_HOME}/.ssh

##########################################
$PROVISION = <<-SCRIPT

	echo -e "root\nroot" | passwd root
	echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
	sed -in 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
	systemctl restart sshd

	mkdir -p /root/.ssh
	
	#echo "127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4 $(uname -n)" > /etc/hosts
	#echo "::1 localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
	#echo "" >> /etc/hosts
	
SCRIPT


##########################################
Vagrant.configure("2") do |config|

	config.vm.provision "shell", env: { "IP_NW_C" => IP_NW_C, "IP_START_C" => IP_START_C, "NUM_CONTROL_NODES" => NUM_CONTROL_NODES }, inline: <<-SHELL			
		for i in `seq 1 ${NUM_CONTROL_NODES}`; do		
			echo "$IP_NW_C$((IP_START_C+i)) #{CONTR_NAME}${i} #{CONTR_NAME}${i}.#{DOMAIN}" >> /etc/hosts
		done
	SHELL
  
	config.vm.provision "shell", env: { "IP_NW_N" => IP_NW_N, "IP_START_N" => IP_START_N, "NUM_WORKER_NODES" => NUM_WORKER_NODES }, inline: <<-SHELL
		for i in `seq 1 ${NUM_WORKER_NODES}`; do
			echo "$IP_NW_N$((IP_START_N+i)) #{NODE_NAME}${i} #{NODE_NAME}${i}.#{DOMAIN}" >> /etc/hosts
		done
	SHELL

	config.vm.provision "shell", env: { "IP_NW_NFS" => IP_NW_NFS, "IP_START_NFS" => IP_START_NFS, "NUM_NFS_SERVERS" => NUM_NFS_SERVERS }, inline: <<-SHELL
		for i in `seq 1 ${NUM_NFS_SERVERS}`; do
			echo "$IP_NW_NFS$((IP_START_NFS+i)) #{NFS_NAME}${i} #{NFS_NAME}${i}.#{DOMAIN}" >> /etc/hosts
		done
	SHELL


	if `uname -m`.strip == "aarch64"
		config.vm.box = settings["software"]["box"] + "-arm64"
	else
		config.vm.box = settings["software"]["box"]
	end
  
	config.vm.box_check_update = false
	config.vm.boot_timeout = 800
 
 
	########################################
	########## CONTROL NODES ###############
	########################################
	(1..NUM_CONTROL_NODES).each do |i|
		config.vm.define "#{LAB_NAME}#{CONTR_NAME}#{i}" do |controlplane|
			controlplane.vm.hostname = "#{CONTR_NAME}#{i}"
			controlplane.vm.network "private_network", ip: IP_NW_C + "#{IP_START_C + i}"
				
			#if settings["shared_folders"]
			#	settings["shared_folders"].each do |shared_folder|
			#		controlplane.vm.synced_folder shared_folder["host_path"], shared_folder["vm_path"]
			#	end
			#end
			
			controlplane.vm.provider "virtualbox" do |vb|
				vb.cpus = settings["nodes"]["control"]["cpu"]
				vb.memory = settings["nodes"]["control"]["memory"]	
				vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]			
				vb.name = "#{LAB_NAME}#{CONTR_NAME}#{i}"
				#vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
			end
		
			controlplane.vm.provision "shell", inline: $PROVISION
		
			controlplane.vm.provision "shell",
				env: {
					"DNS_SERVERS" => settings["network"]["dns_servers"].join(" "),
					"ENVIRONMENT" => settings["environment"],
					"KUBERNETES_VERSION" => settings["software"]["kubernetes"],
					"KUBERNETES_VERSION_SHORT" => settings["software"]["kubernetes"][0..3],
					"OS" => settings["software"]["os"]
				}, 
			path: "scripts/common.sh"
			
			# if vm is controller01 then kubeadm init, otherwise kubeadm join --control-plane
			if "#{i}" == "1"			
				# puts("******** CONTROLLER 1 ********************")
			# controlplane.vm.hostname == "#{CONTR_NAME}1"
				controlplane.vm.provision "shell",
					env: {
						"CALICO_VERSION" => settings["software"]["calico"],
						"CONTROL_IP" => IP_NW_C + "#{IP_START_C + i}",
						"POD_CIDR" => settings["network"]["pod_cidr"],
						"SERVICE_CIDR" => settings["network"]["service_cidr"]
					}, 
				path: "scripts/master.sh"
								
			else
				controlplane.vm.provision "shell",
					env: {
						"CALICO_VERSION" => settings["software"]["calico"],
						"CONTROL_IP" => IP_NW_C + "#{IP_START_C + i}",
						"POD_CIDR" => settings["network"]["pod_cidr"],
						"SERVICE_CIDR" => settings["network"]["service_cidr"]
					}, 
				path: "scripts/extramaster.sh"
			end	
		end	
	end


	########################################
	############# WORKKERS #################
	########################################
	(1..NUM_WORKER_NODES).each do |i|

		config.vm.define "#{LAB_NAME}#{NODE_NAME}#{i}" do |node|
			node.vm.hostname = "#{NODE_NAME}#{i}"
			node.vm.network "private_network", ip: IP_NW_N + "#{IP_START_N + i}"
			#node.vm.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]				
			#if settings["shared_folders"]
			#	settings["shared_folders"].each do |shared_folder|
			#		node.vm.synced_folder shared_folder["host_path"], shared_folder["vm_path"]
			#	end
			#end
		
			node.vm.provider "virtualbox" do |vb|
				vb.cpus = settings["nodes"]["workers"]["cpu"]
				vb.memory = settings["nodes"]["workers"]["memory"]
				vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]	
				vb.name = "#{LAB_NAME}#{NODE_NAME}#{i}"
				#vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
			end
	  
			node.vm.provision "shell", inline: $PROVISION
	  
			node.vm.provision "shell",
				env: {
				  "DNS_SERVERS" => settings["network"]["dns_servers"].join(" "),
				  "ENVIRONMENT" => settings["environment"],
				  "KUBERNETES_VERSION" => settings["software"]["kubernetes"],
				  "KUBERNETES_VERSION_SHORT" => settings["software"]["kubernetes"][0..3],
				  "OS" => settings["software"]["os"]
				},
			path: "scripts/common.sh"
		
			node.vm.provision "shell", path: "scripts/node.sh"

			# Only install the dashboard after provisioning the last worker (and when enabled).
			#if i == NUM_WORKER_NODES and settings["software"]["dashboard"] and settings["software"]["dashboard"] != ""
			#	node.vm.provision "shell", path: "scripts/dashboard.sh"
			#end
	
		end
		
	end
	

	########################################
	############ NFS SERVERS ###############
	########################################
	(1..NUM_NFS_SERVERS).each do |i|

		config.vm.define "#{LAB_NAME}#{NFS_NAME}#{i}" do |nfs|
			nfs.vm.hostname = "#{NFS_NAME}#{i}"
			disk_file = "./storage/disk#{i}.vdi"
			nfs.vm.network "private_network", ip: IP_NW_NFS + "#{IP_START_NFS + i}"
			#node.vm.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
			
			#if settings["shared_folders"]
			#	settings["shared_folders"].each do |shared_folder|
			#		nfs.vm.synced_folder shared_folder["host_path"], shared_folder["vm_path"]
			#	end
			#end
			
			nfs.vm.provider "virtualbox" do |vb|
				vb.cpus = settings["nfs"]["cpu"]
				vb.memory = settings["nfs"]["memory"]
				vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]	
				vb.name = "#{LAB_NAME}#{NFS_NAME}#{i}"
				#vb.customize ["modifyvm", :id, "--hwvirtex", "on"]			
				unless File.exist? disk_file
					vb.customize ['createhd', '--filename', disk_file, '--size', NFS_STORAGE_SIZE]
				end
				vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk_file]
			end
	    
			# puts("#{IP_NW_NFS}")
		
			nfs.vm.provision "shell", inline: $PROVISION
		
			nfs.vm.provision "shell",
				env: {
					"NFS_DIR" => settings["nfs"]["dir"],
					"SUBNET" => "#{IP_NW_NFS}"
				}, 
			path: "scripts/nfs.sh"	

			if settings["ansible"]
				#puts("******** Ansible deploy: yes ********************")
				nfs.vm.provision "shell",
					env: {
						"VERSION" => settings["ansible"]["version"]
					}, 
				path: "scripts/ansible.sh"			
			end

		end
	end

end