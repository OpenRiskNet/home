# Creating cluster for use in testing nextflow pipelines

The purpose of this cluster is to provide a Kubernetes environment where [Nextflow](http://nextflow.io) pipelines
can be executed. Nodes are dedicated to executing Nextflow by means of labels and a default node selector for
the `nextflow` project.

Consolidated logging, metrics and prometheus are installed to allow monitoring.

5 persistent volumes (`nf-pv-000{1-5}`) and corresponding persistent volumes claims (`nf-pvc-000{1-5}`) are present.
These are served by NFS from the `nf-infra` node. To provide input data to the Nextflow workflows ssh to the `nf-infra`
node as the `centos` user and copy data to the `/exports-nf/pv-000{1-5}` directories. The `/exports-nf` direectory is backed by a 300GB cinder
volume, with each PVC being limited to 100GB.

NOTE: this document provides a reference for how this environment was created. The environment may no longer exist. 

## Creating nodes

These are created manually from the `orn-os-04` image:

1. `nf-master`: master and etcd
1. `nf-infra`: router, registry and standard pods
1. `nf-node-1`: standard pods
1. `nf-node-{2-5}`: nextflow pods

A 300GB cinder volume is added to the `nf-infra` node as `/dev/vdb` for data for the Nextflow workflows.

TODO: automate creation of these nodes.

## Installing OpenShift

[Inventory file](inventory)

Deploy using the [openshift/openshift-ansible](https://github.com/openshift/openshift-ansible) repository from the release-3.7 branch:

```
ansible-playbook -i inventory ../openshift-ansible/playbooks/byo/config.yml
```

## Mounting the Cinder volume for NFS storage

On `nf-infra` node:
```
sudo -i
mkfs -t ext4 /dev/vdb
mkdir /exports-nf
mount /dev/vdb /exports-nf
echo '/dev/vdb /exports-nf ext4  defaults 0 0' >> /etc/fstab
```

## Creating NFS mounts

On `nf-infra` node:
```
sudo -i
cd /exports-nf
mkdir pv-0001
mkdir pv-0002
mkdir pv-0003
mkdir pv-0004
mkdir pv-0005
chmod -R 777 pv-*
chown -R nfsnobody.nfsnobody pv-*

cd /etc/exports.d/
echo '/exports-nf/pv-0001 *(rw,root_squash)' >> nextflow.exports
echo '/exports-nf/pv-0002 *(rw,root_squash)' >> nextflow.exports
echo '/exports-nf/pv-0003 *(rw,root_squash)' >> nextflow.exports
echo '/exports-nf/pv-0004 *(rw,root_squash)' >> nextflow.exports
echo '/exports-nf/pv-0005 *(rw,root_squash)' >> nextflow.exports
systemctl restart nfs-server
showmount -e localhost
```

## Setting up users
admin, developer and nextflow users are present.
On `nf-master` node give the admin user extra privs:
```
oc adm policy add-cluster-role-to-user cluster-admin admin
```

## Creating nextflow project

This project has a default node selector that results in pods being created on nf-nodes-{2-5}. Nextflow should have exclusive use of these nodes with all other activity happening on nf-infra and nf-node-1.

On bastion node:
```
oc login https://130.238.28.25.nip.io -u admin
oc adm new-project nextflow --node-selector='zone=worker'
oc adm policy add-role-to-user edit nextflow
```

## Setting up PVs and PVCs
On bastion node in /home/centos/openrisknet-nf dir:
Check the hostname and other details in `nf-pv.yaml` and `nf-pvc.yaml`.
Make sure you are still in the `nextflow` project.


PV and PVC definition:

[nf-pv.yaml](nf-pv.yaml)

[nf-pvc.yaml](nf-pvc.yaml)


Create the PVs and PVCs:
```
oc create -f nf-pv.yaml
oc create -f nf-pvc.yaml
```

