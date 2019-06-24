The Squonk Computational Notebook and its related services can be deployed to the OpenRiskNet environment using Ansible
and the playbooks we've written. Instructions for this can be found in
[Squonk's Ansible Directory](https://github.com/InformaticsMatters/squonk/tree/master/openshift/ansible) on GitHub.

There a number of Ansible **playbooks** and **roles**. The OpenShift templates we use for squonk can be found in the
Squonk Role's [Files](https://github.com/InformaticsMatters/squonk/tree/master/openshift/ansible/roles/squonk/files) directory. Other templates can be found in the corresponding **files** directories of the other **roles** in the project.

Specifically for OpenRiskNet the `openrisknet-infra` project is used to provide the Squonk infrastructure (RabbitMQ, 
PostgreSQL and Keycloak for SSO) which should already have been deployed using 
[these instructions](../openrisknet-infra) and so the section on
**"Deploying the application's infrastructure components"** will not be needed.
You will only need to follow the instructions starting with the
**"Deploying the key application components"** section.

If anything is unclear contact Tim Dudgeon.
