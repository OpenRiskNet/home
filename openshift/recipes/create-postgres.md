# Deploying PostgreSQL

The provides an example of how to deploy an image from a built in template.
The example is for a PostgreSQL database, but the approach should be similar for 
other needs.

The assumption here is that your project needs a central PostgreSQL database that can be
used by other apps in the project. We need to first create postgres and then to manage it 
e.g. create databases and users that an application will use.

## This example requires a persistent volume
It needs a persistent volume of at least 400MB (RWO).
If you haven't created a persistent volume ensure that your
OpenShift server has soem sort of back-end supported (like NFS) and,
if you need to, create a suitable volume.

See the [Creating Persistent Volumes](creating-persistent-volumes-nfs.md) recipe.
    
## Login and create a project
You need a project. If you want to work directly from the example,
copying every step, you will need a `myproject` project in OpenShift:

```
$ oc login -u developer
$ oc new-project myproject
```

## Creating the database

Note: this can also all be done from the web console.

First search for and identify the template to use...

```
$ oc get templates -n openshift | grep postgres
postgresql-persistent               PostgreSQL database service, with persistent storage. For more information ab...   8 (2 generated)   4
```

For full info about the template do:
```
$ oc describe template/postgresql-persistent -n openshift
```
This will describe all the parameters the template uses.

Now use the template to create the database.

```
$ oc process postgresql-persistent -n openshift \
 -p POSTGRESQL_DATABASE=mydb \
 -p POSTGRESQL_USER=myusername \
 -p POSTGRESQL_PASSWORD=secret \
 -p VOLUME_CAPACITY=400Mi \
 -p POSTGRESQL_VERSION=9.5 \
 -p MEMORY_LIMIT=250Mi \
  | oc create -n myproject -f -
```
Here we are providing the parameters needed by the template.
You will need to work out which ones need to be specified.

>   Basic users may not have permission to create projects from templates
    in certain projects. If you are presented with the error
    **error: error processing the template "postgresql-persistent":
    User "developer" cannot create processedtemplates in project "openshift"**
    you will need to add a suitable `role` to the user, as a system aminstrator
    (see below).

If successful you should be presented with a brief summary:
```
secret "postgresql" created
service "postgresql" created
persistentvolumeclaim "postgresql" created
deploymentconfig "postgresql" created
```
   
### Adding admin role to a user
As system administrator you can add roles to users. To give a user
`admin` rights to the `developer` user in the `openshift` project
you can do this (as the `system:admin` from the OpenShift server's command-line)...

```
$ oc login -u system:admin
[...]
$ oadm policy add-role-to-user admin developer -n openshift
role "admin" added: "developer"
```

And you can return to the `developer` user using the login:
```
$ oc login -u developer
```

## Managing the database

Find the pod name:

```
$ oc get po
```

And now connect to it (obviously using the name you're presented with):
```
$ oc rsh postgresql-1-gb0ls
```

In that shell let's create a table:
```
sh-4.2$ psql
postgres=# create table foo (name varchar(100), age int);
CREATE TABLE
postgres=# \dt
        List of relations
 Schema | Name | Type  |  Owner
--------+------+-------+----------
 public | foo  | table | postgres
(1 row)
postgres=# \q
sh-4.2$ exit
```

Now let's kill the pod (again, using the name applicable to your deployment)!

```
$ oc delete pods postgresql-1-gb0ls
pod "postgresql-1-d0z64" deleted
$ oc get po
NAME                 READY     STATUS    RESTARTS   AGE
postgresql-1-jf3km   1/1       Running   0          5m
```
The replication controller spotted that the pod died and replaced it with a new one.
Does it still have our table?

```
$ oc rsh postgresql-1-jf3km
sh-4.2$ psql
psql (9.5.4)
Type "help" for help.

postgres=# \dt
        List of relations
 Schema | Name | Type  |  Owner
--------+------+-------+----------
 public | foo  | table | postgres
(1 row)

postgres=# \q
sh-4.2$ exit
```

Yes it does! This is because the postgres pod was configured to use a persistent volume and that volume
survived the pod being re-created.