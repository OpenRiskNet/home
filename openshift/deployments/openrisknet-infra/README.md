# Ansible role for the OpenRiskNet Infrastructure
This Ansible role (and associated playbook) can be used to create the
Infrastructure project and deploy the key applications, which includes: -

-   KeyCloak/SSO
-   A PostgreSQL database
-   A RabbitMQ messaging service

On a machine with: -

1.  A suitable OC command-line
1.  Access to your cluster's Master API
1.  Ansible (ideally a recent 2.7 version)

This can be your development machine, the bastion or master instance.

You will need to define a number of variables to suit your environment
before running the main playbook by using `setenv-template.sh` as
a starting point: -

    $ cp setenv-template.sh setenv.sh
    [Edit setenv.sh]
    $ source setenv.sh

Install the infrastructure (from this directory) with: -

    $ ansible-playbook playbooks/infra/deploy.yaml

The infrastructure can be removed using the `undeploy` playbook.
Remember hat this deletes everything, so run with caution: -

    $ ansible-playbook playbooks/infra/undeploy.yaml

## Adding and removing databases (and users)
Playbooks exist to create and delete databases and users. You will need
to define the following ansible variables: -

-   `db` The name of the database
-   `db_namespace` The project (namespace) the database will be used from
    The project will be created if it does not exist
-   `db_user` The database user
-   `db_user_password` The database user's password, randomly generated
    if not defined
    
You can put these in a yaml file (i.e. `db.params`) which would look like this: -

    ---
    db: my-db
    db_namespace: my-project
    db_user: me

...and create a database using the following command: -

    $ ansible-playbook playbooks/infra/create-user-db.yaml -e '@db.params'
    
And the DB and user can be removed with the following: -

    $ ansible-playbook playbooks/infra/delete-user-db.yaml -e '@db.params'
