# OpenShift environment

An OpenShift environment comprises of at least the following components:

* At least one **master node**. These monitor what the cluster is being asked to do and makes the corresponding changes.
* At least one **etcd node**. These are where information about the operation of the cluster are stored.
* At least one **infrastructure node*. These are worker nodes to which the core infrastructure (docker repository, routing pods) 
are deployed.

These can all be deployed to the same server, or to different servers. Multiple instances can be deployed for better performance 
and resiliance.

In addition it can contain:

* One or more **worker nodes**. These are standard nodes that non-infrastructrue pods can be deployed to. Typically they are the 
workers of the cluster.
* A **load balancer** node that handles load balancing when using multiple masters.
* Zero or more **nfs nodes** if wanting to use NFS for persistent storage.
* Zero or more **glusterfs** and/or **ceph** nodes if wanting to use these for persistent storage.

## Basic setup

Run master, etcd and infrastructure on a single node (server). For this the node needs to be marked as schedulable and an 
infrastructure node. Allow zero or more worker nodes for scaleability. Define the node as an nfs node allowing persistant
storage across the cluster.
