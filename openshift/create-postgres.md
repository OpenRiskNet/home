# Deploying PostgreSQL

The provides an example of how to deploy an image from a built in template.
The example is for a PostgreSQL database, but the approach should be similar for 
other needs.

The assumption here is that your project needs a central PostgreSQL database that can be
used by other apps in the project. We need to first create postgres and then to manage it 
e.g. create databases and users that an application will use.

## Creating the database

Note: this can also all be done from the web console.

First identify the template to use.

```sh
$ oc get templates -n openshift | grep postgres
postgresql-persistent               PostgreSQL database service, with persistent storage. For more information ab...   8 (2 generated)   4
```

For full info about the template do:
```sh
$ oc describe template/postgresql-persistent -n openshift
```
This will describe all the parameters the template uses.

Now use the template to create the database.

```sh
$ oc process postgresql-persistent -n openshift\
 -p POSTGRESQL_DATABASE=mydb\
 -p POSTGRESQL_USER=myusername\
 -p POSTGRESQL_PASSWORD=secret\
 -p VOLUME_CAPACITY=400Mi\
 -p POSTGRESQL_VERSION=9.5\
 -p MEMORY_LIMIT=250Mi \
  | oc create -n myproject -f -
```

Here we are providing the parameters needed by the template.
You will need to work out which ones need to be specified.

## Managing the database

Find the pod name:

```sh
$ oc get po
```

And now connect to it:
```sh
$ oc rsh postgresql-1-gb0ls
```

In that shell let's create a table:
```sh
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

Now let's kill the pod!

```sh
$ oc delete postgresql-1-gb0ls
pod "postgresql-1-d0z64" deleted
$ oc get po
NAME                 READY     STATUS    RESTARTS   AGE
postgresql-1-jf3km   1/1       Running   0          5m
```
The replication controller spotted that the pod died and replaced it with a new one.
Does it still have our table?

```sh
oc rsh postgresql-1-jf3km
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