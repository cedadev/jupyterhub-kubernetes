# -*- mode: ruby -*-
# vi: set ft=ruby :

N_NODES = 2


def ansible_kube_common(ansible)
  ansible.limit = "all"
  ansible.force_remote_user = false
  ansible.extra_vars = {
    "cluster_interface" => "enp0s8",
  }
  ansible.groups = {
    "kube_masters"  => ["kube-master"],
    "kube_nodes" => (0..N_NODES-1).map { |n| "kube-node%d" % n },
    "kube_hosts:children" => ["kube_masters", "kube_nodes"],
    "vagrant_hosts:children" => ["kube_hosts"],
    "nfs_nodes" => ["kube-node0"],  # The first node has extra storage for NFS
    "glusterfs_nodes" => []  # The current setup has no glusterfs nodes
  }
end


Vagrant.configure(2) do |config|
  config.vm.box = "boxcutter/ubuntu1604"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  # Allow root login with same key as vagrant user
  config.vm.provision :shell, inline: <<-SHELL
  echo "Copying SSH key to root..."
  mkdir -p /root/.ssh
  cp ~vagrant/.ssh/authorized_keys /root/.ssh
  SHELL

  config.vm.define "kube-master" do |master|
    master.vm.hostname = "kube-master"
    master.vm.network "private_network", ip: "172.28.128.101"
  end

  (0..N_NODES-1).each do |n|
    node_name = "kube-node%d" % n
    config.vm.define node_name do |node|
      node.vm.hostname = node_name
      node.vm.network "private_network", ip: "172.28.128.%s" % (102 + n)

      # The first node has an extra disk for the NFS share
      if n == 0
        vdi_file = "./.vagrant/machines/#{node_name}/disk0.vdi"
        node.vm.provider :virtualbox do |vb|
          unless File.exist?(vdi_file)
            vb.customize [ 'createhd',
                           '--filename', vdi_file,
                           '--size', 50 * 1024 ]
          end
          vb.customize [ 'storageattach', :id,
                         '--storagectl', "SATA Controller",
                         '--port', 1,
                         '--device', 0,
                         '--type', 'hdd',
                         '--medium', vdi_file ]
        end
      end

      if n == (N_NODES-1)
        # On the final node (i.e. when all the machines in the cluster have started)
        # we run the playbooks
        # Update packages
        node.vm.provision "ansible-update-packages", type: "ansible" do |ansible|
          ansible.playbook = "ansible/update_packages.yml"
          ansible_kube_common(ansible)
        end
        # Kubernetes cluster setup
        node.vm.provision "ansible-k8s-cluster", type: "ansible" do |ansible|
          ansible.playbook = "ansible/k8s_cluster.yml"
          ansible_kube_common(ansible)
        end
        # Configure NFS provisioner
        node.vm.provision "ansible-nfs-k8s", type: "ansible" do |ansible|
          ansible.playbook = "ansible/nfs_k8s.yml"
          ansible_kube_common(ansible)
        end
        # Configure gluster and heketi
        node.vm.provision "ansible-gluster-k8s", type: "ansible" do |ansible|
          ansible.playbook = "ansible/gluster_k8s.yml"
          ansible_kube_common(ansible)
        end
        # Configure Jupyterhub
        node.vm.provision "ansible-jupyterhub-k8s", type: "ansible" do |ansible|
          ansible.playbook = "ansible/jupyterhub_k8s.yml"
          ansible_kube_common(ansible)
        end
      end
    end
  end
end
