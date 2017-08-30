# Recipes for getting started with Openshift

These recipes are created to allow people to try out OpenShift. The hope is to make it simpler to get over the initial
"help this is all complex and scary" feeling by providing some simple procedures for getting started.

A typical path to follow is:

Fist learn how to setup an OpenShift cluster

1. [Minishift](minishift_local_machine.md) - simple way to get an environment running on your local machine
1. [Deploy CDK Depict](CDK_depict.md) - build and run the small web service application for generating chemical structure depictions CDK Depict
1. [openshift_centos.md](openshift_centos.md) - set up a simple multi-user server environment using `oc cluster up`
1. [Ansible single node](ansible-all-in-one.md) - Simple single server install using Ansible
1. [Ansible simple](ansible-simple.md) - Simple one master, one node setup using Ansible
1. [Ansible metrics + logging](ansible-logging-metrics.md) - Deploy logging and metrics backed by NFS

Then learn about deploying applications

1. [Wordpress + MySQL](wordpress-mysql-example/README.md) - Deploy Wordpress with a MySQL back end usign NFS for persistent storage
1. [Template deploy](template_deploy.md) - deploy a more relistic app from a built in or external template
1. [Postgres database](create-postgres.md) - Deploy a postgres database
1. [Keycloak for SSO](create-sso.md) - Deploy Keycloak for SSO
1. [Django App using Keycloak](django_keycloak_example.md) - Set up Keycloak and a Django app that uses it for authentication

Then learn about CI/CD

1. [Jenkins deploy](jenkins-example/README.md) - demonstrate how a persistent Jenkins can be deployed and a pipeline run
1. [Promotion between projects](promotion_between_projects.md) - learn how to deploy an app and promote it from a dev to a test environment

