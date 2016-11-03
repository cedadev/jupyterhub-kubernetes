# jupyterhub-kubernetes

This project aims to build a Jupyterhub deployment for a Kubernetes cluster.

It also provides a way to provision a test Kubernetes cluster.

## Using the test Kubernetes cluster

In order to provision a test Kubernetes cluster, just run the following:

```
$ vagrant up
```

To access `kubectl` on the master, just use:

```
$ vagrant ssh kube-master -- -l root
[root@master ~]# kubectl ...
```
