# jupyterhub-kubernetes

This project aims to build a JupyterHub deployment for a Kubernetes cluster.

It also provides a way to provision a test Kubernetes cluster using Vagrant.

## Deploying the test cluster

**NOTE:** Notebook storage in the test cluster is ephemeral, and will not be preserved
when the cluster is restarted.

This project uses Ansible playbooks to manage the deployment of the test cluster.
However, there are a couple of limitations on Python and Ansible versions:

  * The playbooks require some features that were only added in Ansible 2.2
  * The playbooks must be run with Python 2 because they use the `b64encode` filter,
    which is affected by the introduction of the differences between `str` and
    `bytes` in Python 3

In order to ensure we are using the correct versions of Python and Ansible, we can
use a virtual environment.

To provision the test cluster, run the following in your checkout directory:

```
$ pip2 install virtualenv    # If not already installed
$ virtualenv venv
$ source venv/bin/activate
(venv) $ pip install 'ansible>=2.2'
(venv) $ vagrant up
...
```

To access `kubectl` on the master, just use:

```
$ vagrant ssh kube-master -- -l root
[root@kube-master ~]# kubectl ...
```

To discover the port on which the Kubernetes Dashboard is running, use the following command:

```
[root@kube-master ~]# kubectl describe svc kubernetes-dashboard -n kube-system | grep NodePort:
```

The dashboard will then be accessible via that port in a browser on the host, e.g. http://172.28.128.101:{port}.

When bringing the cluster up, the Kubernetes manifest files for the various JupyterHub
components are copied to the Kubernetes master (`kube-master`), with some templating of
variables (such as `server_name`).

To start JupyterHub, these components must be started in a specific order:

```
[root@kube-master ~]# cd ~/manifests
[root@kube-master manifests]# kubectl create -f nfs-notebook-storage.yml -f hub-service.yml -f nginx-proxy-nodeport.yml -f nginx-proxy-deployment.yml
service "nfs-provisioner" created
deployment "nfs-provisioner" created
storageclass "notebook-storage" created
service "jupyterhub" created
configmap "jupyterhub-config" created
deployment "jupyterhub" created
service "nginx-proxy" created
secret "nginx-ssl-cert" created
configmap "nginx-conf" created
deployment "nginx-proxy" created
```

Once all the pods have started, JupyterHub will be available at https://172.28.128.101:31443.

## Authentication using CEDA OAuth Server

By default, JupyterHub will use the [dummy authenticator](https://github.com/yuvipanda/jupyterhub-dummy-authenticator),
which means any username/password combination is allowed.

To enable authentication with CEDA accounts using OAuth, you will first need to get
a client ID and client secret from CEDA. Then add the following lines to an appropriate
`host_vars` or `group_vars` file (e.g. `ansible/group_vars/vagrant_hosts`):

```
jupyterhub_image_name: jupyterhub-kubernetes-ceda-oauth
ceda_oauth_client_id: <client id>
ceda_oauth_client_secret: <client secret>
```

When you provision the cluster, the manifest files will be created on `kube-master`
with appropriate settings to use the CEDA OAuth Server for authentication.
