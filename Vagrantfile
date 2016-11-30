# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "wholebits/centos7"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  # Allow root login with same key as vagrant user
  config.vm.provision :shell, inline: <<-SHELL
  echo "Copying SSH key to root..."
  mkdir -p /root/.ssh
  cp ~vagrant/.ssh/authorized_keys /root/.ssh
  SHELL

  N_NODES = 3
  (0..N_NODES-1).each do |n|
    node_name = "kube-node%d" % n
    config.vm.define node_name do |node|
      node.vm.hostname = node_name
      node.vm.network "private_network", ip: "172.28.128.%s" % (101 + n)

      if n == (N_NODES-1)
        # On the final node (i.e. when all the machines in the cluster have started)
        # we run the cluster setup playbook
        node.vm.provision "ansible-kube-cluster", type: "ansible" do |ansible|
          ansible.playbook = "ansible/cluster.yml"
          ansible.limit = "all"
          ansible.force_remote_user = false
          ansible.extra_vars = {
            "cluster_interface" => "eth1",
          }
          ansible.groups = {
            "kube_masters"  => ["kube-node0"],
            "kube_nodes" => (1..N_NODES-1).map { |n| "kube-node%d" % n },
            "kube_hosts:children" => ["kube_masters", "kube_nodes"],
            "vagrant_hosts:children" => ["kube_hosts"],
          }
        end
        # Do JupyterHub-specific configuration
        node.vm.provision "ansible-jupyterhub-k8s", type: "ansible" do |ansible|
          ansible.playbook = "ansible/jupyterhub_k8s.yml"
          ansible.limit = "all"
          ansible.force_remote_user = false
          ansible.extra_vars = {
            "cluster_interface" => "eth1",
          }
          ansible.groups = {
            "kube_masters"  => ["kube-node0"],
            "kube_nodes" => (1..N_NODES-1).map { |n| "kube-node%d" % n },
            "kube_hosts:children" => ["kube_masters", "kube_nodes"],
            "vagrant_hosts:children" => ["kube_hosts"],
          }
        end
      end
    end
  end
end
