# acme-controller deployment

Scripts for deploying the acme controller. 
See here for details about acme controller: [](https://github.com/tnozicka/openshift-acme)

Note that thse scripts use artifacts from that GitHub repo, so those are subject to change.

## Prerequisites

Before running anything setup the environment by running `source setenv.sh`.


## Deploy

Create the project with:

```
oc new-project acme-controller
```

Deploy using:
```
./deploy.sh
```

## Undeploy

```
./undeploy.sh
```

Optionally delete the project with:

```
oc delete project/acme-controller
```

## Usage

Create a http route with the `kubernetes.io/tls-acme: 'true'` annotation and certificate will be generated and deployed as
an https route using edge termination.

