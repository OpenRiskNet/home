# Configuring OpenStack as an OpenShift Cloud Provider

Kubernetes has a very useful concept of a cloud provider that is also available in OpenShift.
The cloud provider allows to handle a number of useful functions in an implementation agnostic manner.
Key functions are volume provisioning, load balancing and autoscaling.

Of most immediate benefit is volume provisioning. We are runnning on OpenStack, so this is by means of Cinder volumes which can be used in two ways:

1. provisioning of volumes into nodes so allowing storage to be directly provided by a Cinder volume (e.g. contrast this with NFS shared volumes). This is useful for infrastructure components like the container registry and storage for consolidated metrics and logging. 
1. dynamic provisioning of Persistent Volume Claims (PVCs) so that a new Persistent Volume (PV) is automatically created backed by a new Cinder volume. The administrator does not need to manually create the PV or create a pool of already generated PVs. They just get created on the fly as they are requested.

Note that in both cases there is no redundancy provided. If this is important then GlusterFS is a better solution.

Setting up OpenStack ass a cloud provider is quite tricky. Before you do this make sure you can deploy an OpenShift cluster without a cloud provider.

## Prerequisites

This was performed on an OpenStack Newton environment with Centos7 images and uses OpenShift Origin version 3.7.1.

The hostnames of the instances that form the OpenShift cluster must be resolvable using DNS. On OpenStack this is best done by means of a dedicated DNS instance.

## Creating the OpenStack instance(s)

In this case we'll use a simple one node environment, with a node name of `all-in-one`, but the same applies to more realistic multi-node environments.

The K8S cloud provider is very pernickety about how it needs to be set up. Key to this is the need for the OpenStack instance name to EXACTLY match the OpenShift hostname. In OpenStack you would typically create an instance named `all-in-one` and OpenStack will give the instance a hostname of `all-in-one.openstacklocal` (or `all-in-one.novalocal` or similar). This is the root of the problem. The hostname is `all-in-one.openstacklocal` but the instance name is just `all-in-one` so the cloud provider blows up when K8S tries to initalise it.

Instead you need to specify `all-in-one.openstacklocal` as the OpenStack instance name whe you create it (so that it is listed in the web console as that name. But by doing so OpenStack will set up the hostname of the instance as `all-in-one.openstacklocal.openstacklocal` which is not what we want. So this hostname has to be changed by SSH-ing to the instance (using its IP address) and then issuing:
```
sudo hostnamectl set-hostname all-in-one.openstacklocal
```

At this point update DNS so that `all-in-one.openstacklocal` resolves to the relevant IP address.

We're now ready to install OpenShift.

## Setting up the Ansible inventory file

Keystone provides the authentication and the location of the OpenStack API endpoints. You need to give OpenShift your Keystone credientials so that it can access the OpenStack API. You can usually locate the Keystone credentials in the OpenStack web console under:

Compute > Access & Security > API Access

Use the Download Openstack RC file link to get a file containing those credentials.
Source this file to define the various `OS_*` environment variables. You will be prompted for your Keystone password.

Getting the settings correct is the next conundrum. Whilst version 3 of the OpenStack APIs have been around for a long time, the Kubernetes OpenStack cloud provider is designed around version 2. A notable change between V2 and V3 is a switch from the term 'tenant' to the term 'project. The V3 keystone.rc file is based around 'project' but the OpenShift configuration needs 'tenant', and there are also cases where both the ID and the name of an item are recognised, but its not clear which ones are really needed.. Working this out needs a bit of guess work and trial and error, but we eventually end up with an answer that works.

Configure the cloud provider by editing your working Ansible inventory file by adding these items to the `[OSEv3:vars]` section:

```
openshift_cloudprovider_kind = openstack
openshift_cloudprovider_openstack_auth_url = "{{ lookup('env','OS_AUTH_URL') }}"
openshift_cloudprovider_openstack_username = "{{ lookup('env','OS_USERNAME') }}"
openshift_cloudprovider_openstack_password = "{{ lookup('env','OS_PASSWORD') }}"
openshift_cloudprovider_openstack_region = "{{ lookup('env', 'OS_REGION_NAME') }}"
openshift_cloudprovider_openstack_domain_name = "{{ lookup('env', 'OS_USER_DOMAIN_NAME') }}"
openshift_cloudprovider_openstack_tenant_id = "{{ lookup('env','OS_PROJECT_ID') }}"

```

Now we need to make sure the host variables are defined correctly. Again, you need to be very precise with this.
```
[masters]
all-in-one

[etcd]
all-in-one

[nodes]
all-in-one openshift_hostname=all-in-one.openstacklocal openshift_schedulable=true openshift_node_labels="{'region': 'infra', 'zone': 'default'}" 
```

## Deploy OpenShift

We're now ready to deploy OpenShift.

```
ansible-playbook -i inventory ~/openshift-ansible/playbooks/byo/config.yml
```

A sample inventory file can be seen [here](inventory-1).

If all goes well you should now have an OpenShift cluster running in about 25 minutes time. The cloud provider is enabled, but not yet being used for much.

If installation fails look in the logs of the nodes:
```
sudo journalctl -xe
```

If you see something like this then you have not set up the instance names and host names correctly:
```
17240 kubelet_node_status.go:106] Unable to register node "all-in-one.openstacklocal" with API server: nodes "orndev-gluster-storage-1.openstacklocal" is forbidden: node all-in-one cannot modify node all-in-one.openstacklocal
```

We said that the cloud provider is not being used for much, but if we look closely we can in fact see something. 
If you list the volumes you will see one named like `kubernetes-dynamic-pvc-84b93e45-26a2-11e8-b6de-fa163ecbeb40`.
What is this? Look at it more closely and you will see that it has these properties:
```
| properties                   | attached_mode='rw', kubernetes.io/created-for/pv/name='pvc-84b93e45-26a2-11e8-b6de-fa163ecbeb40', kubernetes.io/created-for/pvc/name='etcd', kubernetes.io/created-for/pvc/namespace='openshift-ansible-service-broker', readonly='False'
```
This is a dynamic volume created to support a PVC for the Ansible Service Broker. OpenShift magically used a Cinder volume for this rather than an ephemeral volume which would have been used if no cloud provivder was present. Actually its not magic happening, but more on this later. At least for now we know the cloud provider is working nicely!

There's a gotcha with this volume. Whilst OpenShift creates this volume when it is installing the cluster it does not remove it when you run the uninstall.yml playbook. You need to manually detach and delete the volume otherwise every time you run the installer you get a new 1Gi Cinder volume attachced to the instance. 


## Using the cloud provider

Let's use the cloud provider for soemthing useful. We'll use Cinder volumes to back the registry and the consolidated logging and metrics. First undeploy the OpenShift cluster:
```
ansible-playbook -i inventory ~/openshift-ansible/playbooks/adnoc/uninstall.yml
```

For the registry you need to first create a Cinder volume so that it is available for use by the registry. Do not attach it to anything and don't format it. 

Then add this to the `[OSEv3:vars]` section of the inventory file:
```
openshift_hosted_registry_storage_kind = openstack
openshift_hosted_registry_storage_access_modes = ['ReadWriteOnce']
openshift_hosted_registry_storage_openstack_filesystem = xfs
openshift_hosted_registry_storage_openstack_volumeID = "<volume_id>"
openshift_hosted_registry_storage_volume_size = "50Gi"

```
Replace <volume_id> with the Volume ID you created, and adjust the volume size if it wasn't 50Gi.

For metrics and logging you just need to add these to your inventory file:
```
openshift_metrics_install_metrics=true
openshift_metrics_cassandra_storage_type=dynamic

openshift_logging_install_logging=true
openshift_logging_storage_kind=dynamic
```
For these cases the Cinder volumes are created for you and don't need to pre-exist. 

A sample inventory file can be seen [here](inventory-2).

Now run the playbook again:
```
ansible-playbook -i inventory ~/openshift-ansible/playbooks/byo/config.yml
```

If all goes well you should now have a functioning cluster. You will see that Cinder volumes have been created for the metrics and logging PVs and that those volumes have been attached to the appropriate instance.


## Dynamic provisioning of PVCs.

The other key benefit of using the OpenStack cloud provider to provision volumes is for dynamic provisioning of PVCs for your applications. This works in a way that's similar to what happened for the metrics and logging volumes, but the procedure is a bit different.

Firstly connect to the OpenShift API and look at the StorageClass objects:

```
oc get storageClass

```
You will see one type of dynamically provisioned storage class, named `standard`, and it is the default.
This storage class is provisioned by the OpenStack cloud provider by means of Cinder Volumes.
It means that a cluster user can just request a PVC and it will be automatically provided by means of a new Cinder volume.
The cluster admins does not need to do anything, nor do you need a pre-existing pool of PVs ready to be claimed.

To see this in action create a file `test-pvc.yml` containing this PVC definition:
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 name: pvc-engineering
spec:
 accessModes:
  - ReadWriteOnce
 resources:
   requests:
     storage: 5Gi
 storageClassName: standard
```

A sample PVC definition can be seen [here](test-pvc.yml).

By specifying the `storageClassName` of `standard` we are asking for a dynamically provisioned Cinder volume.


Now create that PVC:
```
oc create -f test-pvc.yml
```
And look at what has happened:
```
oc get pvc

```
You'll see that the PV has been created already. And if you look in OpenStack you will see a new Cinder volume for that PV.

And if we now go back to the creation of the volume for the Ansible Service Broker etcd storage then this now makes sense. If you look at the PVC definition you will file that the `storageClass` was set to `standard`, hence why the PVC was satisfied by the cloud provider.

A few of caveats:

1. The only access mode supported is `ReadWriteOnce`. For shared PVCs you need a different approach.
1. There is no redundancy for the Cinder volume (unless that's provided by your OpenStack storage) so you are at risk of the volume failing.
1. This is not really suitable for creating large numbers of PVCs as you may have a quota for Cinder volumes.

GlusterFS might be a better choice for these scenarios.




 
