The Squonk Computational Notebook and its related services can be deployed to the OpenRiskNet environment.
Instructions for this can be found in the openshift branch of the 
[Squonk GitHub repo](https://github.com/InformaticsMatters/squonk/tree/openshift/openshift/templates).

Specifically for OpenRiskNet the `openrisknet-infra` project is used to provide the Squonk infrastructure (RabbitMQ, 
PostgreSQL and Keycloak for SSO) which should already have been deployed using 
[these instructions](../openrisknet-infra) and so the instructions described in the `squonk-infra` directory of the squonk 
repo are not needed. You will only need to follow the instructions in the `squonk-app` directory to deploy the Squonk
application components and related services.

If anything is unclear contact Tim Dudgeon.