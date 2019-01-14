# Example of deploying Wordpress using MySQL

This example is based on the one from 
[here](https://github.com/openshift/origin/tree/release-3.9/examples/wordpress)
updated to apply to the type of environment we use, and simplified and improved
a little. It provides an example of:

1. provisioning pods, services and routes
1. provisioning persistent volumes and persistent volume claims using NFS

## Openshift setup

Create a standard Openshift setup using 
[oc cluster up](https://github.com/OpenRiskNet/home/blob/master/openshift/openshift_centos.md) 
or [Ansible isntaller](https://github.com/OpenRiskNet/home/blob/master/openshift/ansible-all-in-one.md)

Make sure you have provisioned NFS by adding a \[nfs\] section and adding the master to
it. Inventories in our other examples should already have an NFS definition,
as illustrated below:

    [OSEv3:children]
    ...
    nfs
    
    [...]
    
    [nfs]
    MASTER_PRIVATE_FQDN


SSH to the master as the centos user. 

## NFS exports

Do these as root or using sudo.

```
mkdir -p /home/data/pv0001
mkdir -p /home/data/pv0002
chmod -R 777 /home/data/
```

Create `/etc/exports.d/persitent-volumes.exports` and make its contents as:
```
/home/data/pv0001 *(rw,root_squash)
/home/data/pv0002 *(rw,root_squash)
```

As root or using sudo, restart NFS to pick up the changes and check that
the new exports are present.:
```
$ systemctl restart nfs-server
$ showmount -e localhost
Export list for localhost:
/home/data/pv0002       *
/home/data/pv0001       *
...
```

## Clone repo
On the master (as a user that can create persistent volumes i.e. `system:admin`)
clone this repo and move into the dir with these contents:
```
mkdir openrisknet
cd openrisknet/
git clone https://github.com/openrisknet/home
cd home/openshift/wordpress-mysql-example
```

## Create Items

### Project

Create a wordpress project and add our orn1 user to it as editor:
```
oc new-project wordpress
oc policy add-role-to-user edit orn1
```

## Persistent Volumes (PV) and Claim (PVC) creation

>   If you are using a multi-node cluster rather than a single node or minishift
    you will need to modify the `pv-NNNN.yaml` files. Replace
    the `nfs: server:` value with the **Private DNS** value of the master.
    Something like `ip-10-0-0-207.eu-west-1.compute.internal`. Wtihout this
    change, pods started on the application node will not be able to connect to
    NFS, usually emitting the error
    **requested NFS version or transport protocol is not supported**

```
oc create -f pv-0001.yaml
oc create -f pv-0002.yaml
oc create -f pvc-mysql.yaml
oc create -f pvc-wp.yaml
```

Check that the claims have `bound` to the persistent volumes with the
`oc get pv` command:

```
$ oc get pv
NAME      CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS    CLAIM                   STORAGECLASS   REASON    AGE
pv0001    1Gi        RWO,RWX       Recycle         Bound     wordpress/claim-wp                               2m
pv0002    5Gi        RWO           Recycle         Bound     wordpress/claim-mysql                            2m
```
    
### Pods

```
oc create -f pod-mysql.yaml
oc create -f pod-wp.yaml
```
Creating the pods may take a few moments as the Docker images need to be pulled
from the appropriate registry. While you wait you can interrogate the pods using
`oc get po` (`oc get pods`), waiting until the `STATUS` value
becomes `Running` for both...

```
$ oc get po
NAME        READY     STATUS         RESTARTS   AGE
mysql       1/1       Running        0          11m
wordpress   1/1       Running        0          10m
```

### Services

```
oc create -f svc-mysql.yaml
oc create -f svc-wp.yaml
```
Show that the Wordpress service is working by using `oc get svc` to find the wpfrontend
and get its IP address and port.

```
$ oc get svc
NAME         CLUSTER-IP       EXTERNAL-IP                     PORT(S)          AGE
mysql        172.30.114.106   <none>                          3306/TCP         25s
wpfrontend   172.30.99.31     172.29.146.244,172.29.146.244   5055:31151/TCP   17s
```

Then check it is serving content with something like this:
`curl -L http://172.29.146.244:5055`

### Route

Edit the route-wp.yaml to define the correct hostname which will apply to the route.
```
oc create -f route-wp.yaml
```

## Post install

Access Wordpress at something like: https://wordpress.example.com/

Look in the `/home/data/pv0001` and `/home/data/pv0002` directories
to see the wordpress and mysql files.

## Notes

1. The route is not working correctly so Wordpress cannot be accessed. TODO - fix this.

## Potential improvements

1. A proper setup would use a replication controller to ensure the pods are present
and to allow to scale them. TODO - include this.
2. A proper setup would use templates for the pods, services and routes etc. to allow
additional flexibility. 

