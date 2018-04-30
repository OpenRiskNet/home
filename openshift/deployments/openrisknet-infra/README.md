# OpenRiskNet infrastructure deployment

Scripts for deploying OpenRiskNet infrastructure components to the openrisknet-infra project.
Currently this includes a PostgreSQL database, Keycloak for SSO and RabbitMQ as a message queue.
Currently the PostgreSQL database is installed as part of the process of installing Keycloak, so
the only activity revolves around deploying Keycloak, and as a result you get a PostgreSQL database
installed (NOTE: it is expected this will change).
The process for deploying RabbitMQ is also described.

**Note**: This process is abreviated from the process described to deploy the squonk-infra components of the Squonk Computational notebook
that is described [here](https://github.com/InformaticsMatters/squonk/tree/openshift/openshift/templates). Those
instructions may be more up to date. There is no need to deploy the Squonk applications (the squonk-app part) in those instructions.



## Setup

### Configure the Installation

Before you start you must have or create the `admin` (`$OC_ADMIN_USER`) account and grant it `cluster-admin` role.
As the `system:admin` user when on the master node:

```
oc adm policy add-cluster-role-to-user cluster-admin admin
```

Now back on the node where the installation is happening (e.g. the bastion node):

Create/edit `setenv.sh` from the supplied `setenv-template.sh` template. At the very least you
need to define `OC_MASTER_HOSTNAME`, which in minishift is likely to be something 
like `192.168.99.100`. Several other variables will also likely need to be set.

Once done, _source_ the file...

```
source setenv.sh
```

### Test logins

Ensure that you have the `$OC_ADMIN` by testing a login.

>   This forces entering the password, which won't be required again in your
    session therefore avoiding the need for oc passwords later in the process.

```
oc login -u $OC_ADMIN
```

### Create Keycloak image streams

The keycloak deployment is based on that found in the 
[jboss-openshift](https://github.com/jboss-openshift/application-templates/tree/master/sso)
application templates.

As that `admin` user you must deploy the xpaas image streams to your OpenShift environment:

```
oc create -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/sso/sso72-image-stream.json -n openshift
```

This only needs to be done once.

### Create Infrastructure Project

Create project (default name `openrisknet-infra`) as the `$OC_ADMIN_USER` user:
```
oc new-project $OC_INFRA_PROJECT --display-name='ORN Application Infrastructure'
```

>   If you delete the projects you may also need to manually delete the PVs that 
    are created in the next step.


## Create Infrastructure

### Infrastructure PVs and PVCs

Create the PVs required by Postgres and RabbitMQ.

#### If using Minishift:

Minishift comes with 100 PVs ready to use so you only need to create the PVCs:

```
oc process -p INFRA_NAMESPACE=$OC_INFRA_PROJECT -f infra-pvc-minishift.yaml | oc create -f -
```

After completing you should see something like this:

```
$ oc get pvc
NAME               STATUS    VOLUME    CAPACITY   ACCESSMODES   STORAGECLASS   AGE
postgresql-claim   Bound     pv0015    100Gi      RWO,ROX,RWX                  11s
rabbitmq-claim     Bound     pv0002    100Gi      RWO,ROX,RWX                  11s
```

#### If using NFS with OpenShift: 

First create NFS exports on the node that is acting as the NFS server (probably the infrastructure node) 
for `/exports/pv-postgresql` and `/exports/pv-rabbitmq` and then define the PVs and PVCs:

```
oc process -p INFRA_NAMESPACE=$OC_INFRA_PROJECT -p NFS_SERVER=$OC_NFS_SERVER -f infra-pvc-nfs.yaml | oc create -f -
```

This creates PVs for the NFS mounts and binds the PVCs that RabbitMQ and PostgreSQL need. This is 'permanant' coupling
of the PVC to the PV so that this (and any data in the NFS mounts) can be retained between deployments.

Following this you should see something like this (irrelevant entries are excluded):

```
$ oc get pv,pvc
NAME                                          CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS    CLAIM                                   STORAGECLASS   REASON    AGE
pv/pv-postgresql                              50Gi       RWO           Retain          Bound     openrisknet-infra/postgresql-claim                               2h
pv/pv-rabbitmq                                1Gi        RWO           Retain          Bound     openrisknet-infra/rabbitmq-claim                                 2h

NAME                   STATUS    VOLUME          CAPACITY   ACCESSMODES   STORAGECLASS   AGE
pvc/postgresql-claim   Bound     pv-postgresql   50Gi       RWO           standard       2h
pvc/rabbitmq-claim     Bound     pv-rabbitmq     1Gi        RWO           standard       2h
```

>   Note: if re-using these PVs/PVCs you will need to delete the contents of the volume (the
    `/exports/pv-postgresql` and `/exports/pv-rabbitmq` directories) or you may get permissions
    problems when postgres and rabbitmq initialise.

Now we are ready to start deploying the infrastructure.

#### If using dynamic provisioning with OpenShift:

Dymanic provisioning allows to only specfy the PVS and OpensShift will satisfy the request dynamically
using whatever dynamic provision is configured. You can use the StorageClass property to define
what type of storage you need.

This is tested with Cinder volumes on OpenStack but other mechanisms should also work.
Dynamic provisioning msut be set up on OpenShift before you start.

From the infra project create the PVCs (with OpenShift creating the PVs for you) using:

```
oc process -p STORAGE_CLASS=standard -p POSTGRESQL_VOLUME_SIZE=125Gi -f infra-pvc-dynamic.yaml | oc create -f -
```

>   Note: use whatever value you need for the STORAGE_CLASS and POSTGRESQL_VOLUME_SIZE properties.

>   Note: if re-using the postgres PV/PVC you will need to delete the contents of the volume (the
    `/exports/pv-postgresql` directory) or you may get permissions problems when postgres initialises.


### Deploy PostgreSQL, RabbitMQ and SSO

Deploy PostgreSQL, RabbitMQ and Keycloak to the infrastructure project:

```
./sso-postgres-deploy.sh
./rabbitmq-deploy.sh
```

To get postgres running in Minishift you might need to
set permissions on the PV that is used. e.g.

```
minishift ssh -- sudo chmod 777 /mnt/sda1/var/lib/minishift/openshift.local.pv/pv0091
```
(lookup the appropriate PV to fix)

>   NOTE: With Minishift you may stumble on the defect
    `redhat-sso-7/sso70-openshift image fails to start`
    (https://bugzilla.redhat.com/show_bug.cgi?id=1408453) which manifests
    itself with a _Could not rename /opt/eap/standalone/configuration/standalone_xml_history/current_
    exception and the Pod failing to start. As the `admin` user in the
    `openrisknet-infra` project you should be able to work-aropund the problem
    with the following command:
     
     oc volume dc/sso --add --claim-size 512M --mount-path /opt/eap/standalone/configuration/standalone_xml_history --name standalone-xml-history 

Check that the infrastructure components are all running (e.g. use the web console).
It may take several minutes for everything to start.


### Undeploy

Run the `sso-postgres-undeploy.sh` and `rabbitmq-undeploy.sh` scripts to undeploy these applications.
Note that the PVCs are NOT deleted by these scripts to avoid accidental loss of data.
Delete thesee manually if needed.

