# Creating OpenShift Persistent Volumes

## NFS
The following recipe creates two persistent volumes, using NFS,
suitable for some of the OpenShift demonstrations.

Do these as root or using sudo on the OpenShift server:

    $ mkdir -p /home/data/pv0001
    $ mkdir -p /home/data/pv0002
    $ chmod -R 777 /home/data/

Create `/etc/exports.d/persitent-volumes.exports` and make its contents as:

    /home/data/pv0001 *(rw,root_squash)
    /home/data/pv0002 *(rw,root_squash)

As root or using sudo, restart NFS to pick up the changes and check that
the new exports are present:

    $ systemctl restart nfs-server
    $ showmount -e localhost
    Export list for localhost:
    /home/data/pv0002       *
    /home/data/pv0001       *
    ...

Create persistent volume definitions using YAML (say `pv-0001.yaml` and
`pv-0002.yaml`).  These examples illustrate 1GiB (RWO) and 5GiB (RWO + )
volumes for the directories you created earlier:

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0001
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: localhost
    path: /home/data/pv0001
```

and...

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0002
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: localhost
    path: /home/data/pv0002
```

>   If you are using a multi-node cluster rather than a single node or minishift
    replace the `nfs: server:` value with the **Private DNS** value of the master.
    Something like `ip-10-0-0-207.eu-west-1.compute.internal`. Wtihout this
    change, pods started on the application node will not be able to connect to
    NFS, usually emitting the error
    **requested NFS version or transport protocol is not supported**

Unless your OpenShift user has suitable privilege you'll need to to the
following as the `system:admin` user:

    $ oc login -u system:admin
    
    $ oc create -f pv-0001.yaml
    $ oc create -f pv-0002.yaml

You can the check that the persistent volumes with the `oc get pv` command:

    $ oc get pv
    NAME      CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS    CLAIM                   STORAGECLASS   REASON    AGE
    pv0001    1Gi        RWO,RWX       Recycle         Available                                                  2m
    pv0002    5Gi        RWO           Recycle         Available                                                  2m

## Binding a PVC to your NFS PV

Often you create a NFS PV for a specific reason and want to create a specific PVC for it.
This can be error prone if not done correctly as the PVC might not bind to the PV you want.
To fix this you can tell the PVC the name of the PV you want it to bind to and tell the PV
the name of the PVC that is allowed to claim it. To be absolutely sure you need to do both.

This can be done using the following template:

```

# Usage:
#
# oc process -f pvc-nfs.yaml -p NAME=myvol -p NFS_SERVER=myserver -p NFS_PATH=/data/mydir -p SIZE=5Gi -p NAMESPACE=myproject | oc create -f -
#
# The NFS export specified by the NFS_PATH parameter must exist on the server specified by the NFS_SERVER parameter. 


kind: Template
apiVersion: v1
metadata:
  name: fs-pv-nfs
  annotations:
    description: Creates a NFS PV and binds a PVC to it
labels:
  template: pvc-nfs

parameters:

# the NFS server name
- name: NFS_SERVER
  required: True
# the directory path to mount
- name: NFS_PATH
  required: True
# the name to use for the PV and PVC. Will end up with names like pv-name and pvc-name
- name: NAME
  required: True
# the size of the pv/pvc e.g. 5Gi
- name: SIZE
  required: True
# the read/write mode.
- name: MODE
  value: ReadWriteMany
# the PVs persistentVolumeReclaimPolicy
- name: RECLAIM
  value: Retain
# the naemspces we are in
- name: NAMESPACE
  required: True

objects:

- kind: PersistentVolume
  apiVersion: v1
  metadata:
    name: pv-${NAME}
  spec:
    capacity:
      storage: ${SIZE}
    accessModes:
    - ${MODE}
    persistentVolumeReclaimPolicy: ${RECLAIM}
    nfs:
      server: ${NFS_SERVER}
      path: ${NFS_PATH}
    claimRef:
      name: pvc-${NAME}
      namespace: ${NAMESPACE}

- kind: PersistentVolumeClaim
  apiVersion: v1
  metadata:
    name: pvc-${NAME}
    namespace: ${NAMESPACE}
  spec:
    volumeName: pv-${NAME}
    accessModes:
    - ${MODE}
    resources:
      requests:
        storage: ${SIZE}
    storageClassName: ''
```
>   Note the last line in this PVC definition where the `storageClassName` is set to the empty string. This is necessary if you have 
    dynamic provisioning enabled otherwise the PVC will try to use the default StorageClass to dynamically create your volume rather
    than use the PV that you wanted.
