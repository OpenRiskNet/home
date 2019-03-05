# Deploying JupyterHub to OpenShift

This is entirely based on the work of Graham Dumpleton <gdumplet@redhat.com> who has been very helpful in getting this
set up. Mostly it is based on instructions found in his
[jupyter-notebooks](https://github.com/jupyter-on-openshift/jupyter-notebooks) and
[jupyterhub-quickstart](https://github.com/jupyter-on-openshift/jupyterhub-quickstart)
GitHub repos.

An earlier version of the instructions can be found [here](README-v1.md).

Unlike the earlier instructions all artifacts used are checked into this repo avoid problems with changes in remotely
located files.

What is deployed is:

* A new project named `jupyter` where all the action takes place.
* s2i builders for basic, scipy and tensorflow notebook images.
* A new `jupyterhub` database in the PostgreSQL database that resides in the `openrisknet-infra` project, along with a
secret in this `jupyter` project that contains the database credentials.
* JupyterHub.
* Notebooks and hub support JupyterLab interface
* SSO using Keycloak from the `openrisknet-infra` project.

## Prerequistes

OpenShift cluster with:

* Dynamic volume provisioning (e.g. using GlusterFS)
* A PostgreSQL database running in the `openrisknet-infra` project.
* Red Hat SSO (Keycloak) running in the `openrisknet-infra` project with a suitable realm (e.g. `openrisknet`)

## Deploy

The main deployment can be done as a user without `cluster-admin` privs. However, provisioning of the PostgreSQL database
in the `openrisknet-infra` project does need admin privs.

### new project
```
oc new-project jupyter
```

### Build Jupyter images
```
oc create -f templates/build-configs/s2i-minimal-notebook.yaml
oc create -f templates/build-configs/s2i-scipy-notebook.yaml
oc create -f templates/build-configs/s2i-tensorflow-notebook.yaml
```
This takes about 15 mins. Whilst that is running you can get some other things ready.

### Create the image stream for the JupyterHub image

```
oc create -f templates/image-streams/jupyterhub.yaml
```

### Load the template to deploy JupyterHub

```
oc create -f templates/jupyterhub/jupyterhub-deployer.yaml
```

### Set up SSO

In Keycloak go to the appropriate realm (e.g. `openrisknet`) and add `jupyterhub` as a new client.
Specify `confidential` as the `Access Type`. 
The Redirect URL will need to be something like `https://jupyterhub-jupyter.prod.openrisknet.org/*` (or whatever you specify
as the `ROUTE_NAME` parameter when you deploy JupyterHub).

You will need to know the client secret that is generated.

### Set up the PostgreSQL database

Unlike Graham Dumpleton's templates which provision a PostgreSQL database in the `jupyter` project just for the `jupyterhub`
application we instead use the central database that is in the `openrisknet-infra` project.
To do this we run a database provisioner playbook that creates a new database named `jupyterhub`, a database user named
`jupyterhub` and a randomly generated password for that user.
These are stored in a secret in the `jupyter` project and used by the `jupyterhub` pod.

__Note__: this playbook is currently located in the [Squonk repo](https://github.com/InformaticsMatters/squonk). It will soon 
be added to this repo. 

As an admin user you need to source the appropriate `setenv.sh` file that describes your OpenShift environment. 
This is the file that you used to create the environment (if not available then these environment variables need to be set:
OC_MASTER_URL, OC_ADMIN, OC_ADMIN_PASSWORD, OC_INFRA_PROJECT, OC_POSTGRESQL_SERVICE, OC_INFRA_SA).

Then run:

```
ansible-playbook playbooks/infra/create-user-db.yaml -e new_db=jupyterhub -e new_db_user=jupyterhub -e new_db_namespace=jupyter
```

Once added you can check for a secret named `database-credentials-jupyterhub` in the `jupyter` project that contains the
database connection details.

If you need to delete these you can run:

```
ansible-playbook playbooks/infra/delete-user-db.yaml -e db=jupyterhub -e db_user=jupyterhub
```

After running those playbooks you need to switch back to the jupyter project:

```
oc project jupyter
```

### JupyterHub Configuration

Create the jupyterhub_config.py configuration file. A template named `jupyterhub_config_template.py` is provided in this 
dir but you may want different options. You can store these configurations in the `jupyterhub_configs` dir which is excluded 
from git.
You must replace the correct value for the `c.OAuthenticator.client_secret` property, the various URLs, and maybe some
other values. 

TODO: work out how to specify the need for specific role(s) for authorisation.


### Deploy

Deploy it using:
```
oc new-app --template jupyterhub-deployer --param JUPYTERHUB_CONFIG="`cat jupyterhub_configs/jupyterhub_config.py`"
```
If you want a different hostname for the route (the default will be something like `jupyterhub-jupyter.your.domain.org`)
you can specify this as the `ROUTE_NAME` parameter. e.g. add `--param ROUTE_NAME=jupyter.prod.openrisknet.org` to that 
command.

The value of the `JUPYTERHUB_CONFIG` is used to create a ConfigMap named `jupyterhub-cfg`. If you need to change the settings
you can edit that ConfigMap and re-deploy JupyterHub.

## Delete
Delete the deployment (buildconfigs, imagestreams, secrets and pvcs (user's notebooks) will remain):
```
oc delete all,configmap,serviceaccount,rolebinding --selector app=jupyterhub
```

Or delete everything:
```
oc delete project jupyter
```

### TLS

By default trusted TLS certificates are not deployed. Once you are happy with the setup you can change this by changing 
the value of the `kubernetes.io/tls-acme` annotation for the route to `true`. You should also update the `jupyterhub_config.py`
file to set the appropriate TLS settings (in two places) and then redeploy.

## Database backups

__Note__: This section is no longer relevant as the database is now located in the `openrisknet-infra` project so backups 
need to be handled there.

These example templates provide backups of your JupyterHub database
using the Informatics Matters backup container image.

>   For the following recipe to work the JupyterHub database must be configured
    to permit remote access to the admin account, i.e. a password must be
    provided in the database Pod's `POSTGRESQL_ADMIN_PASSWORD` environment
    variable. If a password is not set you can run `psql -U postgres` from
    within the Pod and change the password with the `\password` meta command
    of psql.

-   [PVC](backup-pvc.yaml)
-   [CronJob](backup.yaml)

The backup image provides rich control of actions
through a number of container environment variables.

The backup essentially creates a compressed SQL file from the
result of running a `pg_dumpall` command.

The example template has a backup schedule that results in the
backup running at **00:07** each day whilst maintaining a history of
**4** of the most recent backups.

>   If you want to change the total number of backups that are held set the
    `BACKUP_COUNT` parameter, with `-p BACKUP_COUNT=<n>`.

To deploy the backup, using an OpenShift login on the Jupyter project,
first create the storage and then start the CronJob. You will need
the admin password of the database and (optionally) the host and
admin user (defaulted to `jupyterhub-db` and `jupyterhub` respectively).

So, if the admin password is `xyz123` and you're using the default Jupyter
database host service name and admin username you can deploy with the
following sequence of commands, after logging onto OpenShift as an admin user:

```
oc project jupyter
oc process -f backup-pvc.yaml | oc create -f -
oc process -f backup.yaml -p PGADMINPASS=xyz123 | oc create -f -
```

Or, with a different host, the backup can be deployed with: -

```
oc process -f backup.yaml -p PGADMINPASS=xyz123 \
    -p PGHOST=jupyterhub-db | oc create -f -
```

### Database recovery
A recovery image can be launched using the example Job template.

-   [Job](recovery.yaml)

This template, which has the same database user parameters as the backup
template, and attempts to recover the database from the latest backup can
be run with the following command: -

```
oc process -f recovery.yaml -p PGADMINPASS=xyz123 \
    -p PGHOST=jupyterhub-db | oc create -f -
```

>   It is important to ensure that the backup CronJob is not running
    or will not run when you recover the database.
 
