# -*- mode: ruby -*-
# vi: set ft=ruby :

N_NODES = 1


def ansible_kube_common(ansible)
  ansible.limit = "all"
  ansible.force_remote_user = false
  ansible.extra_vars = {
    "cluster_interface" => "enp0s8",
  }
  ansible.groups = {
    "bastion_hosts" => ["bastion"],
    "nfs_hosts" => ["nfs-server"],
    "kube_masters"  => ["kube-master"],
    "kube_nodes" => (0..N_NODES-1).map { |n| "kube-node%d" % n },
    "kube_hosts:children" => ["kube_masters", "kube_nodes"],
    "vagrant_hosts:children" => ["bastion_hosts", "nfs_hosts", "kube_hosts"]
  }
end


Vagrant.configure(2) do |config|
  config.vm.box = "boxcutter/ubuntu1604"

  # We need to allow SSH between nodes, but don't care about security, so just
  # use the Vagrant insecure private key
  config.ssh.insert_key = false
  config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  # Allow root login with same key as vagrant user
  config.vm.provision :shell, inline: <<-SHELL
  echo "Copying SSH key to root..."
  mkdir -p /root/.ssh
  cp ~vagrant/.ssh/authorized_keys /root/.ssh
  SHELL

  config.vm.define "bastion" do |bastion|
    bastion.vm.hostname = "bastion"
    bastion.vm.network "private_network", ip: "172.28.128.100"
  end

  config.vm.define "nfs-server" do |nfs|
    nfs.vm.hostname = "nfs-server"
    nfs.vm.network "private_network", ip: "172.28.128.101"

    # Give the node an extra disk for /export
    vdi_file = "./.vagrant/machines/nfs-server/disk0.vdi"
    nfs.vm.provider :virtualbox do |vb|
      unless File.exist?(vdi_file)
        vb.customize [ 'createhd',
                       '--filename', vdi_file,
                       '--size', 100 * 1024 ]
        vb.customize [ 'storageattach', :id,
                       '--storagectl', "SATA Controller",
                       '--port', 1,
                       '--device', 0,
                       '--type', 'hdd',
                       '--medium', vdi_file ]
      end
    end
  end

  config.vm.define "kube-master" do |master|
    master.vm.hostname = "kube-master"
    master.vm.network "private_network", ip: "172.28.128.102"
  end

  (0..N_NODES-1).each do |n|
    node_name = "kube-node%d" % n
    config.vm.define node_name do |node|
      node.vm.hostname = node_name
      node.vm.network "private_network", ip: "172.28.128.%s" % (103 + n)

      if n == (N_NODES-1)
        # On the final node (i.e. when all the machines in the cluster have started)
        # we run the playbooks
#        node.vm.provision "ansible-update-packages", type: "ansible" do |ansible|
#          ansible.playbook = "ansible/update_packages.yml"
#          ansible_kube_common(ansible)
#        end
        node.vm.provision "ansible-setup-etc-hosts", type: "ansible" do |ansible|
          ansible.playbook = "ansible/setup_etc_hosts.yml"
          ansible_kube_common(ansible)
        end
        node.vm.provision "ansible-k8s-cluster", type: "ansible" do |ansible|
          ansible.playbook = "ansible/k8s_cluster.yml"
          ansible_kube_common(ansible)
        end
        node.vm.provision "ansible-nfs-provisioner", type: "ansible" do |ansible|
          ansible.playbook = "ansible/nfs_provisioner.yml"
          ansible_kube_common(ansible)
        end
        node.vm.provision "ansible-k8s-dashboard", type: "ansible" do |ansible|
          ansible.playbook = "ansible/k8s_dashboard.yml"
          ansible_kube_common(ansible)
        end
        node.vm.provision "ansible-jupyterhub-k8s", type: "ansible" do |ansible|
          ansible.playbook = "ansible/jupyterhub_k8s.yml"
          ansible_kube_common(ansible)
        end
        node.vm.provision "ansible-setup-bastion", type: "ansible" do |ansible|
          ansible.playbook = "ansible/setup_bastion.yml"
          ansible_kube_common(ansible)
        end
      end
    end
  end
end
