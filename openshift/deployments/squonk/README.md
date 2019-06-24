The Squonk Computational Notebook and its related services can be deployed to the OpenRiskNet environment using Ansible
and the playbooks we've written. Instructions for this can be found in the
[Squonk's Ansible Directory](https://github.com/InformaticsMatters/squonk/tree/master/openshift/ansible) on GitHub.

Specifically for OpenRiskNet the `openrisknet-infra` project is used to provide the Squonk infrastructure (RabbitMQ, 
PostgreSQL and Keycloak for SSO) which should already have been deployed using 
[these instructions](../openrisknet-infra) and so the section on
**Deploying the application's infrastructure components** will not be needed.
You will only need to follow the instructions starting with the
**Deploying the key application components** section.

If anything is unclear contact Tim Dudgeon.
