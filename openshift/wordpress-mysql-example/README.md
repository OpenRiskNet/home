# Example of deploying Wordpress using MySQL

This example is based on the one from 
[here](https://github.com/openshift/origin/tree/master/examples/wordpress)
updated to apply to the type of environment we use, and simplified and improved
a little. It provides an example of:

1. provisioning pods, services and routes
1. provisioning persistent volumes and persistent volume claims using NFS

## Openshift setup

Create a standard Openshift setup using 
[oc cluster up](https://github.com/OpenRiskNet/home/blob/master/openshift/openshift_centos.md) 
or [Ansible isntaller](https://github.com/OpenRiskNet/home/blob/master/openshift/ansible-all-in-one.md)

Make sure you have provisioned NFS by adding a \[nfs\] section and adding the master to
it:

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

Create /etc/exports.d/persitent-volumes.exports and make its contents as:
```
/home/data/pv0001 *(rw,root_squash)
/home/data/pv0002 *(rw,root_squash)
```

As root or using sudo, restart NFS to pick up the changes and check that
the new exports are present.:
```
systemctl restart nfs-server
showmount -e localhost
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

## PC and PVC creation

```
oc create -f pv-0001.yaml
oc create -f pv-0002.yaml
oc create -f pvc-mysql.yaml
oc create -f pvc-wp.yaml
```

### Pods

```
oc create -f pod-mysql.yaml
oc create -f pod-wp.yaml
```
Creating the pods may take a few mins as the Docker images need to be pulled.
You can interrogate the pods using `oc get po` (`oc get pods`) and wait
until the `STATUS` value becomes `Running` for both.

### Services

```
oc create -f svc-mysql.yaml
oc create -f svc-wp.yaml
```
Show that the Wordpress service is working by using `oc get svc` to find the wpfrontend
and get its IP address and port. Then check it is serving content with something like this:
`curl -L http://172.29.187.206:5055`

### Route

Edit the route-wp.yaml to define the correct hostname which will apply to the route.
```
oc create -f route-wp.yaml
```

## Post install

Access Wordpress at something like: https://wordpress.example.com/

Look in the `/home/data/pv0001` and `/home/data/pv0002` directories to see the wordpress
and mysql files.

## Notes

1. The route is not working correctly so Wordpress cannot be accessed. TODO - fix this.

## Potential improvements

1. A proper setup would use a replication controller to ensure the pods are present
and to allow to scale them. TODO - include this.
2. A proper setup would use templates for the pods, services and routes etc. to allow
additional flexibility. 

