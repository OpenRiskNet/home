# Fixing glusterfs mounts that fail to detach

## Symptom
A pod hangs in `Terminating` state and never terminates

## Cause
The the glusterfs volume fails to umount on the node where the pod is running.
This seems to be a Kubernetes/OpenShift bug.

## Solution

From the bastion node do a `oc login -u <username>`.

Find the node(s) where this is happening:

`oc get pod -n squonk -o wide`
 
For each of those nodes:

`ssh <node-name> mount | grep gluster`

Check those mounts against the name of the pvs:

 `oc get pv | grep gluster`

It's the bit after the `/volumes/kubernetes.io~glusterfs/` part that is of interest. That will be the name of the pv.

Do this *carefully* - you don't want to unmount a volume that is in use!

If not a current pv then manually unmount it on the node with something like this:

`ssh <node-name> sudo umount <volume-name>`

For instance, it will look something like this:

`ssh orn-node-007.openstacklocal sudo umount /var/lib/origin/openshift.local.volumes/pods/3986a643-b5b6-11e8-961c-fa163eca01d7/volumes/kubernetes.io~glusterfs/pvc-c73650d9-b5b1-11e8-961c-fa163eca01d7`

Once unmounted the pod should terminate, but this might take up to 5 mins.
