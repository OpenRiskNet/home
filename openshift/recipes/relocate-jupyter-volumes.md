# Notes for how to relocate jupyter notebook volumes from one ORN VE to another

This was needed when the ORN reference site was transferred from Uppmax to JGU. 
We wanted to ensure that users notebooks would be present on the new environment.

This is overview of what was done and will need adapting to other scenarions.
It is not a runnable process as it stands.
It assumes that you have SSH connections set up.

## 1. Copy data

Jupyter notebook data is present in NFS exports that are accessed as Persisted Volumes (PVs).

### ssh to infra node on Uppmax site.

```
cd /nfs-jupyter
tar cvfz notebook-vols.tgz vol*
```

### scp files to your machine

From bastion:

```
scp prod-infra:/nfs-jupyter/notebook-vols.tgz .
scp prod-infra:/etc/exports.d/nfs-jupyter.exports .
```

From local machine:

```
mkdir tmp/jupyter-clone/ 
cd tmp/jupyter-clone/
scp old-orn-bastion:notebook-vols.tgz .
scp old-orn-bastion:nfs-jupyter.exports .
```

### Copy files to JGU

```
scp notebook-vols.tgz jgu-infra:.
scp nfs-jupyter.exports jgu-infra:.
```

## Export PV and PVC data

From local machine:

```
oc login -u admin https://prod.openrisknet.org
oc get pv --selector='purpose=jupyter' -o yaml --export=true > pv.yaml
oc get pvc --selector='app=jupyterhub,component=singleuser-storage' -o yaml --export=true > pvc.yaml

grep -v creationTimestamp: pv.yaml | grep -v resourceVersion: | grep -v selfLink: | grep -v uid: | grep -v status: | grep -v phase: | sed 's/prod-infra/cloudv199/' > pv-clean.yaml

grep -v creationTimestamp: pvc.yaml | grep -v resourceVersion: | grep -v selfLink: | grep -v uid: | grep -v status: | grep -v pv.kubernetes.io/b | grep -v phase: > pvc-clean.yaml
```

If the path for the NFS exports differs on the two sites further edits will be needed.

## NFS setup

If the path for the NFS exports differs on the two sites edits to the `nfs-jupyter.exports` file will be needed.

As sudo:

```
cp /home/centos/nfs-jupyter.exports /etc/exports.d/
systemctl restart nfs
showmount -e localhost
```

## Create PVs and PVCs

From local machine:

```
scp pv-clean.yaml jgu-master:.
scp pvc-clean.yaml jgu-master:.
```

From new master node at JGU

```
oc login -u admin
oc create -f pv-clean.yaml 
oc create -f pvc-clean.yaml
```

If you need to delete them to try again:

```
oc delete pvc --selector='app=jupyterhub'
oc delete pv --selector='purpose=jupyter'
```
