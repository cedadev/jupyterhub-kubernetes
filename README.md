# jupyterhub-kubernetes

This project aims to build a JupyterHub deployment for a Kubernetes cluster.

It also provides a way to provision a test Kubernetes cluster using Vagrant.

This project uses Ansible playbooks to manage the deployment of the test cluster.
However, the playbooks must be run with Python 2 because they use the `b64encode`
filter, which is affected by the introduction of the differences between `str`
and `bytes`in Python 3.

In order to ensure we are using the correct version of Python, we can use a virtual
environment:

```
$ pip2 install virtualenv    # If not already installed
$ virtualenv venv
$ source venv/bin/activate
(venv) $ pip install ansible
(venv) $ ... other ansible/vagrant commands ...
```


## Deploying the test cluster

The test cluster is deployed using [Vagrant](https://www.vagrantup.com/) and
[VirtualBox](https://www.virtualbox.org/), so make sure you have recent versions
of both installed.

By default the Kubernetes cluster consists of a master and a single 'minion' or
'worker'. The number of workers can be increased by changing `N_NODES` at the top
of the `Vagrantfile`.

There are also two support machines - a 'bastion' host, which is used for proxying
requests to the `NodePort` services defined in the Kubernetes cluster, and an NFS
server that provides storage for the cluster.

JupyterHub is deployed with the [dummy authenticator](https://github.com/yuvipanda/jupyterhub-dummy-authenticator),
which means any username/password combination is allowed. However, you may want to
change the admin usernames in `ansible/group_vars/vagrant_hosts`.

The cluster will also have the [Kubernetes](https://github.com/kubernetes/dashboard)
and [Grafana](http://docs.grafana.org/) dashboards installed. These will be accessible
using the username `admin` and the `dashboard_password` configured in
`ansible/group_vars/vagrant_hosts`.

The test cluster is provisioned by activating the virtual environment created
above and running `vagrant up`:

```
$ source venv/bin/activate
(venv) $ vagrant up
```

Once the cluster is deployed, JupyterHub will be available at https://172.28.128.100.

The Kubernetes dashboard will be available at https://172.28.128.100:8002 and the
Grafana dashboard will be available at https://172.28.128.100:8001.

To access `kubectl` on the master, just use:

```
$ vagrant ssh kube-master -- -l root
[root@kube-master ~]# kubectl ...
```
