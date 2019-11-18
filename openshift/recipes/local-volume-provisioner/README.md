# Configuring and using a Logical Volume Local Volume Provisioner
From the OpenShift v3.11 documentation **Local Volumes** are...

>   ...persistent volumes (PV) that represent locally-mounted file systems,
    including raw block devices. A raw device offers a more direct route to
    the physical device and allows an application more control over the timing
    of I/O operations to that physical device. This makes raw devices suitable
    for complex applications such as database management systems that
    typically do their own caching. Local volumes have a few unique features.
    Any pod that uses a local volume PV is scheduled on the node where the
    local volume is mounted.

So they're local, fast but you're responsible for resilience (backups) but
they're great for services that need low-latency access to disk-based data.

In this document we're going to explain how you configure and use logical
volumes as local volumes in your OpenShift deployment by first configuring
a local drive with logical volumes followed by configuration of the provisioner
in OpenShift.

Two valuable online resources that you might want to refer to are: - 

-   OpenShift's [Configuring Local Volumes] documentation
-   HowToGeek's [What is Logical Volume Management] article
-   HowToGeek's [Logical Volume Management] guide

## Setting-up your Logical Volume device
The best starting-point for your device is to set it up as a **logical volume**,
this is extremely valuable because volumes are easy to dynamically resize,
create and delete.

>   If your volume is up to 2TByte you can use `fdsisk` as a formatting
    utility. If your volume is greater than 2TB you will need to use something
    else like `parted`. Both are common unix disk utilities and we'll be
    using `parted` here.

>   Here we assume the physical volume we want to use for local storage is
    known to unix as `/dev/sdc`, obviously your devise is likely to be different.
    Make sure you use the right device - some of the following commands are
    catastrophic to say the least if used on the wrong device.

Let's start by running the partitioning/formatting tool on a clean
(empty) 4TByte device to create a primary partition. In our device
the volume size is actually 3841Gi, as can be seen via `parted`'s `print`
instruction: -

    $ sudo -i
    $ parted /dev/sdc
    (parted) print
    [...]
    Disk /dev/vdb: 3841GB
    [...]
    
> You might have to remove any partitions that exist if the device is not clean.

    (parted) mklabel gpt
    [respond to the prompt]
    (parted) mkpart primary 0GB 3841GB
    (parted) print
    Model: ATA INTEL SSDSC2KB03 (scsi)
    Disk /dev/sdc: 3841GB
    Sector size (logical/physical): 512B/4096B
    Partition Table: gpt
    Disk Flags: 

    Number  Start   End     Size    File system  Name     Flags
    1      1049kB  3841GB  3841GB               primary

    (parted) quit
    Information: You may need to update /etc/fstab.
    #

With the device primary partition created we can create our logical volume
with a **physical volume**, **volume group** and finally,
an example **logical volume**.

Create a physical volume for our partition (we've only created one partition
and so the partition will be `/dev/sdc1`)...

    # pvcreate /dev/sdc1

Now create a volume group and give it a name. Here we're using the name
`graphpool`...

    # vgcreate graphpool /dev/sdc1

That's it. Now we just need to create individual volumes in the group
that we want to use in our OpenShift applications, format them and
mount them into the host filesystem.

## Creating (and mounting) logical volumes 
Let's create two volumes, an `lva` and a `lvb` of approximately 50Gi and 200Gi
respectively: -

    # lvcreate -L 50G -n lva graphpool
    # mkfs -t ext4 /dev/graphpool/lva

    # lvcreate -L 200G -n lvb graphpool
    # mkfs -t ext4 /dev/graphpool/lvb

OpenShift encourage you to mount the individual volumes into `/mnt/local-storage`.
In there we create a directory that will also be used as the _storage class_.
Our volumes will be mounted to `/mnt/local-storage/ssd/a` and
`/mnt/local-storage/ssd/b`...

    # mkdir -p /mnt/local-storage/ssd/a
    # mount -t ext4 /dev/graphpool/lva /mnt/local-storage/ssd/a

    # mkdir -p /mnt/local-storage/ssd/b
    # mount -t ext4 /dev/graphpool/lvb /mnt/local-storage/ssd/b

You need to make all volumes accessible to the processes
running within the containers. You can change the labels of mounted file
systems to allow this, for example: -

    # chcon -R unconfined_u:object_r:svirt_sandbox_file_t:s0 /mnt/local-storage/

You will also need to add the mounted volumes to `/etc/fstab` so the
volume is remounted should the server restart.

Use `blkid` to obtain the UUID of your volumes, here's an example
with our two devices: -

    # blkid
    /dev/mapper/graphpool-lva: UUID="0a563b3e-1d26-4746-914b-f54c768f4bef" TYPE="ext4" 
    /dev/mapper/graphpool-lvb: UUID="0a30efcc-b3e3-4308-8a5a-1ec695a31ba4" TYPE="ext4" 

Each of the UUIDs need to be placed into your `/etc/fstab`, with something like
the following lines: -

    UUID=0a563b3e-1d26-4746-914b-f54c768f4bef /mnt/local-storage/ssd/a ext4  defaults 0 2
    UUID=0a30efcc-b3e3-4308-8a5a-1ec695a31ba4 /mnt/local-storage/ssd/b ext4  defaults 0 2

You should test the `/etc/fstab` entries by un-mounting the volumes and then
remounting using the table entries. This is valuable to ensure that the table
is correct - once the server reboots it's probably too late. e.g.: -

    # umount  /mnt/local-storage/ssd/a
    # mount -a

We've: -

-   formatted a drive for logical volume management
-   created a logical group
-   created two volumes
-   formatted the volumes
-   mounted the volumes in the file-system

Now we simply have to configure and deploy the OpenShift provisioner...

## Configuring the OpenShift Local Volume Provisioner
From this point it's essentially following the OpenShift documentation. Here
we'll provide examples for the volume we've created.

We need to provide a **StorageClass** for our `/mnt/local-storage/ssd/*` volumes,
and we'll use the class name `local-ssd`
(probably in the file `storage-class-ssd.yaml): -

    ---
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: local-ssd
    provisioner: kubernetes.io/no-provisioner
    volumeBindingMode: WaitForFirstConsumer

And we need to provide OpenShift with a map of mount points for each class
we define. Here we only have one class so our **ConfigMap** (probably
in the file `local-volume-configmap.yaml`) will be: -

    ---
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: local-volume-config
    data:
      storageClassMap: |
        local-ssd: 
          hostDir: /mnt/local-storage/ssd
          mountDir: /mnt/local-storage/ssd

Let's create an OpenShift project (we'll call ours `local-storage`),
a service account and install our storage classes and class map: -

    $ oc new-project local-storage
    $ oc create serviceaccount local-storage-admin
    $ oc adm policy add-scc-to-user privileged -z local-storage-admin
    $ oc create -f ./local-volume-configmap.yaml
    $ oc create -f ./storage-class-ssd.yaml

Now we just need to install a template from which we'll create the
provisioner. Here we use the example provided by OpenShift: -

    $ oc create -f https://raw.githubusercontent.com/openshift/origin/release-3.11/examples/storage-examples/local-examples/local-storage-provisioner-template.yaml

From here we can deploy the provisioner (which manifests itself as a
**DaemonSet** with pods running on each node)...

    $ oc new-app \
        -p CONFIGMAP=local-volume-config \
        -p SERVICE_ACCOUNT=local-storage-admin \
        -p NAMESPACE=local-storage \
        -p PROVISIONER_IMAGE=quay.io/external_storage/local-volume-provisioner:v2.3.2 \
        local-storage-provisioner

>   We have to provide a different `PROVISIONER_IMAGE` because the one
    in the OpenShift example (at the time of writing) does not work.

After a few moments you should be able to find a provisioner pod
running in the project for each of your nodes. In our case we have three
nodes in our cluster...

    $ oc get po -n local-storage
    NAME                             READY     STATUS    RESTARTS   AGE
    local-volume-provisioner-gl8tg   1/1       Running   0          2h
    local-volume-provisioner-m2s59   1/1       Running   0          2h
    local-volume-provisioner-qcdvq   1/1       Running   0          2h

And, as we've already created our volumes, you should find a
**Persistent Volume** created automatically for us, ready to use. The
names are not obvious .

    $ oc get pv | grep local-ssd
    local-pv-521dab9a                          49Gi       RWO
    local-pv-b83d1b47                          787Gi      RWO

But we can see that `local-pv-521dab9a` is mapped to `/mnt/local-storage/ssd/b`
when we _describe_ the volume: -

    $ oc describe pv local-pv-521dab9a
    [...]
    Source:
        Type:  LocalVolume (a persistent volume backed by local storage on a node)
        Path:  /mnt/local-storage/ssd/b

Now, every time we add new volumes and mount them under
`/mnt/local-storage/ssd` the OpenShift local volume provisioner
will automatically create a corresponding **Persistent Volume**.

## Using local volumes (by name)
In order to use a specific local volume in a deployment we simply need to
provide a suitable **Persistent Volume Claim** that refers to the volume
we need (by name). In our ca`se we could provide the following: -

	---
	kind: PersistentVolumeClaim
	apiVersion: v1
	metadata:
	  name: local-pv-claim
	spec:
	  accessModes:
	  - "ReadWriteOnce"
	  resources:
	    requests:
	      storage: 49Gi
	  storageClassName: local-ssd
	  volumeName: local-pv-521dab9a

>   Remember that a 50Gi logical volume will loose some space to the
    formatting overhead. So, if you do need 50Gi then you will need
    to create a larger volume, say 51Gi. The actual size you
    will need is left for you to find through experimentation.

---

[configuring local volumes]: https://docs.openshift.com/container-platform/3.11/install_config/configuring_local.html
[logical volume management]: https://www.howtogeek.com/howto/40702/how-to-manage-and-use-lvm-logical-volume-management-in-ubuntu
[what is logical volume management]: https://www.howtogeek.com/howto/36568/what-is-logical-volume-management-and-how-do-you-enable-it-in-ubuntu
