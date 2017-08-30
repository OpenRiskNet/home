# Deploy persistent Jenkins

Example of how to deploy Jenkins that uses adn NFS backed Persistent Volume for storage.
This is based of the OpenShift example found 
[here](https://github.com/openshift/origin/tree/master/examples/jenkins).

## Openshift setup

Create a standard Openshift setup using 
[oc cluster up](https://github.com/OpenRiskNet/home/blob/master/openshift/openshift_centos.md) 
or [Ansible isntaller](https://github.com/OpenRiskNet/home/blob/master/openshift/ansible-all-in-one.md)

Make sure you have provisioned NFS by adding a \[nfs\] section and adding the master to
it.

SSH to the master as the centos user. 

## NFS exports

Do these as root or using sudo.

```
mkdir -p /home/data/pv0003
chmod -R 777 /home/data/pv0003
```

Create or edit /etc/exports.d/persitent-volumes.exports and add a line like this:
```
/home/data/pv0003 *(rw,root_squash)
```

Restart NFS to pick up the changes and check that the new exports are present.:
```
systemctl restart nfs-server
showmount -e localhost
```

## Create Items

### Project

Create a cicd project and add our orn1 user to it as editor:
```
oc new-project cicd
oc policy add-role-to-user edit orn1
```

## PC creation

Create a YAML file named pv-0003.yaml for the PV with this content.
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0003
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: localhost
    path: /home/data/pv0003
```

Now create the Persistent Volume.
```
oc create -f pv-0003.yaml
```

## Install Jenkins

```
oc new-app jenkins-persistent
```

Add the sample project stuff for which there is a sample Jenkins build configuration:
```
oc new-app -f https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/application-template.json
```

## Run build

Connect to the Openshift console and check that the jenkis-persistent application in 
the cicd project. If all looks good Click on the route to open the Jenkins console. 
Login etc. and you should see Jenkins.

There should be an `OpenShift Sample` build configuration.
Perform a build and check it compeltes successfuly.






