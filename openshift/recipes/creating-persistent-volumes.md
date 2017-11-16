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
