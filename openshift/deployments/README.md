# OpenRiskNet deployments

This directory contains procedures for deploying components to the OpenRiskNet OpenShift infrastructure.
It provides a relatively simple approach to populating the OpenShift environment with the necessary components.

These deployments are fairly opinionated about how they are deployed so as to try to standardize and simplify the 
process. For instance, assumptions are made about project (namespace) names and the names of services etc. If you
stray from these standards then things might not work. Be warned!

## General approach

Each sub-directory contains procedures for populating a single project (Kubernetes namespace). Sometimes a single 
component is deployed, sometimes multiple ones.

Some projects will be dependent on other projects already existing. Read the README.md for the project for details.

We try to avoid risk of doing operations in the wrong project or as the wrong user by providing a setenv.sh script in each project.
Once you move into that project source that script using `source setenv.sh` and after that all scripts *should* fail to run if you
are in the wrong project. 

The README.md in each project gives details of how to proceed. Typically there will be scripts for deploying and undeploying.
Undeploying will typically not remove PVs and PVCs to avoid the risk of losing critical data, so you will need to manage those 
manually.

For a generic guide to getting your deployments production ready look [here](ProductionDeploymentGuide.md).

## Setup

In this directory you must create the file `setup.sh` using `setenv-example.sh` as an example. Edit to to reflect your environment.

Some of these deployments require admin privileges. We assume a user named 'admin' for this. To set up such a user do this:

```
oc adm policy add-cluster-role-to-user cluster-admin admin
```

Alternatively change the value of the OC_ADMIN environment variable that is set in the setenv.sh file in this directory.

## Current components/projects

It is suggested you deploy these projects in this order.

1. acme-controller (recommended) - provides TLS support for routes using Let's Encrypt certificates
1. openrisknet-infra (essential) - Core OpenRiskNet infrastructure that can used by any OpenRiskNet application. Currently includes PostgreSQL database and Keycloak Single Sign On (SSO)
1. jenkins (optional) - Jenkins CI/CD system
