# Creating NFS Jupyter volumes
You can use a template and a couple of simple bash-scripts to define
large numbers of volumes.

## NFS directory creation
On the NFS server, assuming your jupyter volume is mounted at
`/nfs-jupyter` you could run this bash script to create directories
with the numbers `N` to `M`: -

```
#!/bin/bash

# Creates directories in /nfs-jupyter
# and echos lines that can be added to the nfs exports file
#
# Alan Christie
# November 2019

for ((id="$1";id<="$2";id++))
do
  sudo mkdir -p /nfs-jupyter/vol"$id"
  sudo chown nfsnobody.nfsnobody /nfs-jupyter/vol"$id"
  sudo chmod 0770 /nfs-jupyter/vol"$id"
  echo "/nfs-jupyter/vol$id *(rw,root_squash)"
done
```

i.e. to create volumes 51 to 100:

    ./create-dir-script.sh 51 100
    
The script also emits lines suitable for inclusion in an `.exports`
file (typically `/etc/exports.d/nfs-jupyter.exports`).

With the lines ppaced in an `.exports` file restart the NFS service
with something like: -

    sudo systemctl restart nfs-server
    
## Volume template
The following template can be used to create an OpenShift
**Persistent Volume** (`pv`).

The volume needs to have an access mode of `ReadWriteOnce`
and have a label of `pupose=jupyter`.

A working template follows: -

```
---
kind: Template
apiVersion: v1
metadata:
  name: jupyter-pv

parameters:

- name: PV_NUMBER
  required: yes

objects:

- kind: PersistentVolume
  apiVersion: v1
  metadata:
    labels:
      purpose: jupyter
    name: jupyter-${PV_NUMBER}
  spec:
    accessModes:
    - ReadWriteOnce
    capacity:
      storage: 1Gi
    nfs:
      path: /nfs-jupyter/vol${PV_NUMBER}
      server: cloudv199
    persistentVolumeReclaimPolicy: Retain
```

## Creating the PVs
From a server that has the OC command-line tool, and the
above template (named `pv-jupyter-template.yaml`),
you can create a batch of PVs with the following
bash script: -

```
#!/bin/bash

# Creates PVs for Jupyter to match the expected exported volumes
# Uses a template to create the PV
#
# Alan Christie
# November 2019

for ((id="$1";id<="$2";id++))
do
  oc process -f pv-jupyter-template.yaml -p PV_NUMBER="${id}" | oc create -f -
done
```

And run it like this (to create PVs 51 to 100): -

    ./create-jupyter-pv.sh 51 100
