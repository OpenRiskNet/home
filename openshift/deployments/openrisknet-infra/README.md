# OpenRiskNet infrastructure deployment

Scripts for deploying OpennRiskNet infrastructure components to the openrisknet-infra project.
Currently this includes a PostgreSQL database and Keycloak for SSO.
Currently the PostgreSQL database is installed as part of the process of installing Keycloak, so
the only activity revolves around deploying Keycloak, and as a result you get a PostgreSQL database
installed (NOTE: it is expected this will change). 


## Prerequisites and Assumptions

Create the project using:
```
oc new-project openrisknet-infra
```

Before running anything setup the environment by running `source setenv.sh`.

You must generate the necessary certificates for Keycloak in the `certs` directory as described 
[here](../../sso). You can do this in one simple step by running the `certs-create.sh` script. 
All certs and keystores are protected with the password defined in the OC_CERTS_PASSWORD environment 
variable that is defined in the setenv.sh script.

Make sure the image streams are loaded. If you have the openshift/openshift-ansible repo checked out do this using:
```
oc create -f $HOME/git/openshift/openshift-ansible/roles/openshift_examples/files/examples/v3.6/xpaas-streams/jboss-image-streams.json -n openshift
```

or pull directly from GitHub:
```
oc create -f https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v3.6/xpaas-streams/jboss-image-streams.json -n openshift
```

## Deploy

This project uses a PVC for PostgreSQL storage. Make sure a PV is available. The `pv-postgresql-template.yaml' file
can be used as an example.


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

     
## Undeploy


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

## TODO

1. Use trusted root certificate
1. Break apart deployment of PostgreSQL and Keycloak

