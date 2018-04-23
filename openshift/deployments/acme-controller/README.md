# acme-controller deployment

Scripts for deploying the acme controller. 
See here for details about acme controller: [https://github.com/tnozicka/openshift-acme](https://github.com/tnozicka/openshift-acme)

Note that thse scripts use artifacts from that GitHub repo, so those are subject to change.

## Prerequisites

Before running anything setup the environment by running `source setenv.sh` and check the output to ensure
the correct settings are present.


## Deploy

Login as the admin user.
Create the project with:

```
oc new-project $OC_PROJECT
```

Deploy using:
```
./deploy.sh
```

## Undeploy


Delete the project with:

```
oc delete project/acme-controller
```

## Usage

Create a http route with the `kubernetes.io/tls-acme: 'true'` annotation and certificate will be generated and deployed.
For example the metadata section of the route yaml should look like this:
```
metadata:
  annotations:
    kubernetes.io/tls-acme: 'true'
```

If no HTTPS route definition already exists a new one is created using edge termination.


