# Backup and restore a PostgreSQL database

These instructions are for manually backing up a single PostgreSQL database, and then restoring it.

This uses the `pg_dump` program which exports the contents of the specified database as a series of SQL statements
which can subsequently be read back into the datatabase. `pg_dump` does not manage users as these are of 'global'
scope. When restoring the necessary users must already exist, but this will usually be the case when you are restoring
a database into the same server. To save the global parameters you can use `pg_dumpall --globals-only`.

## Backing up

This uses `oc rsh` to get into the psotgres pod and then runs `pg_dump`. This creates the dump file inside the container
from where it can be copied. In principle it might be better to use `oc exec` but the PATH is not set up correctly and 
`pg_dump` cannot be run. If exporting a very large database you might need to temporarily mount a volume into the pod and 
save the data there to avoid filling up the root partition of the container.

```
oc rsh db-postgresql-1-tt85j
# you are now inside the container
cd
# dump the database named sso
pg_dump sso > sso.sql
# dump the globals in case they are needed
pg_dumpall --globals-only > globals.sql
exit
# now back on the host. copy the dump files.
oc cp db-postgresql-1-tt85j:/var/lib/pgsql/sso.sql .
oc cp db-postgresql-1-tt85j:/var/lib/pgsql/globals.sql .
```

## Restoring

```
oc rsh db-postgresql-1-tt85j
# you are now inside the container
cd
# drop the old database
psql -c 'drop database sso'
# create a new empty database
createdb -T template0 sso
# do the import
psql sso < sso.sql
```
