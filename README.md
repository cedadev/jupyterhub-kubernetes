# jupyterhub-kubernetes

This project aims to build a [JupyterHub](https://jupyterhub.readthedocs.io/en/latest/)
deployment for a [Kubernetes](https://kubernetes.io/) cluster.

It also provides an [Ansible](https://www.ansible.com/) playbook to provision a
Kubernetes cluster.


## Deploying the test cluster

The test cluster is deployed using [Vagrant](https://www.vagrantup.com/) and
[VirtualBox](https://www.virtualbox.org/), so make sure you have recent versions
of both installed.

By default the Kubernetes cluster consists of a master and a single minion/worker.
The number of workers can be increased by changing `N_NODES` at the top of the
`Vagrantfile`.

There are also two support machines - a 'bastion' host, which is used for proxying
requests to the `NodePort` services defined in the Kubernetes cluster (in production,
this would also be your only route in via SSH), and an NFS server that provides
storage for the cluster.

JupyterHub is deployed with the [dummy authenticator](https://github.com/yuvipanda/jupyterhub-dummy-authenticator),
which means any username/password combination is allowed. However, you may want to
change the admin usernames in `ansible/group_vars/vagrant_hosts`.

The cluster will also have the following add-ons installed:

  * [Kubernetes dashboard](https://github.com/kubernetes/dashboard)
  * [Heapster with InfluxDB and Grafana](https://github.com/kubernetes/heapster/blob/master/docs/influxdb.md)
  * [Fluentd with Elasticsearch and Kibana](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch)

To provision the test cluster, just run `vagrant up`.

Once the cluster is deployed, JupyterHub will be available at https://172.28.128.100.
The first notebook server you spawn may take a while to spin up, as it has to pull
the Docker image for the notebook server from Docker Hub (which is large!).

To access `kubectl` on the master, just use:

```
$ vagrant ssh kube-master -- -l root
[root@kube-master ~]# kubectl ...
```

Alternatively, you can install `kubectl` on your host system, and use the config
file that was pulled from the `kube-master` during the Ansible playbook:

```
$ export KUBECONFIG=./ansible/.artifacts/vagrant/kubernetes-admin.conf
$ kubectl ...
```

This method is particularly useful for accessing the various dashboards by running
`kubectl proxy`.

The main Kubernetes dashboard will then be available at http://localhost:8001/ui.

To see the suffixes for the other dashboards (Grafana and Kibana), run
`kubectl cluster-info`:

```
$ kubectl cluster-info
Kubernetes master is running at https://172.28.128.102:6443
Elasticsearch is running at https://172.28.128.102:6443/api/v1/proxy/namespaces/kube-system/services/elasticsearch-logging
Heapster is running at https://172.28.128.102:6443/api/v1/proxy/namespaces/kube-system/services/heapster
Kibana is running at https://172.28.128.102:6443/api/v1/proxy/namespaces/kube-system/services/kibana-logging
KubeDNS is running at https://172.28.128.102:6443/api/v1/proxy/namespaces/kube-system/services/kube-dns
monitoring-grafana is running at https://172.28.128.102:6443/api/v1/proxy/namespaces/kube-system/services/monitoring-grafana
monitoring-influxdb is running at https://172.28.128.102:6443/api/v1/proxy/namespaces/kube-system/services/monitoring-influxdb
```

Although these services look like they are accessible directly via the IP of the
`kube-master`, they are not - visiting them will yield this error:

```
User "system:anonymous" cannot proxy services in the namespace "kube-system".
```

Instead, they should be accessed by using `kubectl proxy` and replacing
`https://172.28.128.102:6443` with `http://localhost:8001`.
