# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "geerlingguy/centos7"

  # Use a dhcp allocated private network for cluster comms
  config.vm.network :private_network, type: "dhcp"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  # Allow root login with same key as vagrant user
  config.vm.provision :shell, inline: <<-SHELL
  echo "Copying SSH key to root..."
  mkdir -p /root/.ssh
  cp ~vagrant/.ssh/authorized_keys /root/.ssh
  SHELL

  config.vm.define "nfs-server" do |nfs|
    nfs.vm.hostname = "nfs-server"
  end

  config.vm.define "kube-master" do |master|
    master.vm.hostname = "kube-master"
  end

  N_NODES = 2
  node_names = (1..N_NODES).map { |n| "kube-node%02d" % n }
  (1..N_NODES).zip(node_names).each do |n, node_name|
    config.vm.define node_name do |node|
      node.vm.hostname = node_name

      if n == N_NODES
        node.vm.provision :ansible do |ansible|
          ansible.playbook = "jupyterhub/playbook.yml"
          ansible.limit = "all"
          ansible.force_remote_user = false
          ansible.groups = {
            "nfs_servers" => ["nfs-server"],
            "kube_masters"  => ["kube-master"],
            "kube_nodes" => node_names,
            "kube_hosts:children" => ["kube_masters", "kube_nodes"],
            "vagrant_hosts:children" => ["nfs_servers", "kube_hosts"],
          }
          ansible.extra_vars = {
            "cluster_interface" => "enp0s8",
          }
        end
      end
    end
  end
end
