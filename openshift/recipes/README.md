# Recipes for getting started with OpenShift

These recipes are created to allow people to try out OpenShift. The hope is to make it simpler to get over the initial
"help this is all complex and scary" feeling by providing some simple procedures for getting started.

The recipes in this directory are mainly for illustration and training purposes. 
Note that there are more concrete examples in the [environments](../environments) and [deployments](../deployments) directories 
that are used in the creation of a real OpenRiskNet Virtual Research Environment. 

A typical path to follow is:

First learn how to setup an OpenShift cluster

1. [Minishift](minishift_local_machine.md) - simple way to get an environment running on your local machine
1. [Cluster up](openshift_centos.md) - set up a simple multi-user server environment using `oc cluster up`
1. [Ansible one node](ansible-simple-one.md) - Simple joint master and node using Ansible
1. [Ansible two node](ansible-simple-two.md) - Simple one master, one node setup using Ansible
1. [Ansible metrics + logging](ansible-logging-metrics.md) - Deploy logging and metrics backed by NFS
1. [Nextflow cluster](nextflow-cluster/) - Create cluster for testing [Nextflow](http://nextflow.io) pipelines
1. [Openstack Cloud Provider](openstack-cloud-provider/) - Using the Openstack Cloud Provider for provisioning volumes

Then learn about deploying applications

1. [Manual deploy CDK Depict](CDK_depict/CDK_depict.md) - use the web console to build and run the small web service application for generating chemical structure depictions CDK Depict
1. [Template deploy CDK Depict](CDK_depict/templates.md) - same as above but using templates and the CLI
1. [Wordpress + MySQL](wordpress-mysql-example/README.md) - Deploy Wordpress with a MySQL back end using NFS for persistent storage
1. [Template deploy](template_deploy.md) - deploy a more relistic app from a built in or external template
1. [Postgres database](create-postgres.md) - Deploy a postgres database
1. [Keycloak for SSO](sso/README.md) - Deploy Keycloak for SSO
1. [Get token from Keycloak](keycloak-get-token/README.md) - How to authenticate to Keycloak and get an access token
1. [Django App using Keycloak](django_keycloak_example.md) - Set up Keycloak and a Django app that uses it for authentication
1. [Tomcat App using Keycloak](https://github.com/OpenRiskNet/example-java-servlet/blob/master/KEYCLOAK.md) - deploy the example servlet using Keycloak for SSO
1. [TLS for routes](certificates/README.md) - securing routes using TLS/HTTPS
1. [Certificate Renewal](certificate-renewal/README.md) - an ansible way of renewing certificates

Then learn about CI/CD

1. [Jenkins deploy](jenkins-example/README.md) - demonstrate how a persistent Jenkins can be deployed and a pipeline run
1. [Promotion between projects](promotion_between_projects.md) - learn how to deploy an app and promote it from a dev to a test environment

Additional information

1. [How DNS works on OpenShift](https://blog.openshift.com/dns-changes-red-hat-openshift-container-platform-3-6/)

