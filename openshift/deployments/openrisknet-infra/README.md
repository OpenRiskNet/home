# OpenRiskNet infrastructure deployment

Scripts for deploying OpenRiskNet infrastructure components to the openrisknet-infra project.
Currently this includes a PostgreSQL database, Keycloak for SSO and RabbitMQ as a message queue.
Currently the PostgreSQL database is installed as part of the process of installing Keycloak, so
the only activity revolves around deploying Keycloak, and as a result you get a PostgreSQL database
installed (NOTE: it is expected this will change).
The process for deploying RabbitMQ is also described.


## Prerequisites and Assumptions

Create the project using:
```
oc new-project openrisknet-infra
```

Before running anything you must create the file `setup.sh` using `setenv-example.sh` as an example 
and setup the environment byrunning `source setenv.sh`. You must already have set up the `setup.sh`
file in the directory above this.

# SSO and PostgreSQL

You must generate the necessary certificates for Keycloak in the `certs` directory as described 
[here](../../sso). You can do this in one simple step by running the `certs-create.sh` script. 
All certs and keystores are protected with the password defined in the OC_CERTS_PASSWORD environment 
variable that is defined in the setenv.sh script.

Make sure the image streams are loaded. If you have the openshift/openshift-ansible repo checked out do this using:
```
oc create -f $OPENSHIFT_ANSIBLE_GIT/roles/openshift_examples/files/examples/v${OPENSHIFT_VERSION}/xpaas-streams/jboss-image-streams.json -n openshift
```

or pull directly from GitHub:
```
oc create -f https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v3.6/xpaas-streams/jboss-image-streams.json -n openshift
```

## Deploy SSO and PostgreSQL

**IMPORTANT**: This project uses a PVC for PostgreSQL storage. Make sure a PV is available. The `pv-postgresql-template.yaml' file
can be used as an example if using NFS.


Prepare the environment using:
```
./sso-env-deploy.sh
```

Define the necessary secrets (certs, passwords etc.) using:
```
./sso-secrets-deploy.sh
```

Deploy using:
```
./sso-deploy.sh
```
Note: this deploys additional secrets with details of the PostgreSQL and Keycloak usernames and passwords.

>   NOTE: You may stumble on the defect
    `redhat-sso-7/sso70-openshift image fails to start`
    (https://bugzilla.redhat.com/show_bug.cgi?id=1408453) which manifests
    itself with a _Could not rename /opt/eap/standalone/configuration/standalone_xml_history/current_
    exception and the Pod failing to start. As the `admin` user in the
    `openrisknet-infra` project you should be able to work-aropund the problem
    with the following command:
     
     oc volume dc/sso --add --claim-size 512M --mount-path /opt/eap/standalone/configuration/standalone_xml_history --name standalone-xml-history 

You might also need to change the permissions on the PV that is claimed by Postgresql is you get a 'permission denied'
error in the Posgtresql pod. If this happens identify the PV that is being used by the `postgresql-claim` PVC, connect
to the server providing the PV and do a chmod 777 on the directory. e.g. for Minishift something like this:
```
minishift ssh -- sudo chmod -R 777 /var/lib/minishift/openshift.local.pv/pv0068
```

Keycloak is deployed with the admin user of `admin` with a randomly generated password that can be found in the `sso` secret
under the key of `sso-admin-password`.
Similar for the Keycloak service user named `manager` who's password is stored under the `sso-service-password` key.

     
## Undeploy SSO and PostgreSQL


```
./sso-undeploy.sh
```

Optionally delete the secrets:
```
./sso-secrets-undeploy.sh
```

Optionally delete the service accounts and permissions:
```
./sso-env-undeploy.sh
```

Optionally delete the project using:
```
oc delete project/openrisknet-infra
```

You may want to clean up the PV that was used following undeploying.

## TODO for SSO and PostgreSQL

1. HIGH: Use trusted root certificate.
1. LOW: Break apart deployment of PostgreSQL and Keycloak.
1. LOW: Investigate having a hot standby PostgreSQL instance for high availability.

# RabbitMQ

## Deploy RabbitMQ

Make sure that the `openrisknet-infra` project has been created and that you have edited and sourced the `setenv.sh` file.

```
./rabbitmq-deploy.sh
```

The passwords and erlang cookie that are generated during deployment are stored in a secret named `rabbitmq`.

## Undeploy RabbitMQ

```
./rabbitmq-undeploy.sh
```

## TODO for RabbitMQ

1. HIGH: Provide persistent volumes for the queue storage.
1. LOW: Make the deployment neutral in nature so that it can be used in non OpenRiskNet projects (primarily the location of
files in `/etc/openrisknet/`).
1. MEDIUM: Investigate security risks (including the implications of the `guest` user).
1. MEDIUM: Expose the RabbitMQ web console (with authentication hooked into the OpenShift OAuth authentication).
1. LOW: Investigate clustering RabbitMQ instances for high availability and scalability.
