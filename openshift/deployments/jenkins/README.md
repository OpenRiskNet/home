# Jenkins deployment

Scripts for deploying Jenkins 

Note that the jenkins-template.yaml is a slightly modified version of the template from
[here](https://github.com/openshift/origin/blob/master/examples/jenkins/jenkins-persistent-template.json).
Check that significant enhancements have not been made to this.

## Prerequisites and Assumptions

1. This is deployed to a project named 'jenkins'
1. The acme-contoller is already deployed so that TLS certificates are generated

Before running anything setup the environment by running `source setenv.sh`.


## Deploy

This project uses a PVC for jenkins storage. Make sure a PV is available. The `jenkins-pv-template.yaml' file
can be used as an example.

Create the project using:
```
oc new-project jenkins
```

Deploy using:
```
./deploy.sh
```

## Undeploy

The undeploy.sh script removes what was deployed but does not remove any build or build configs that were added.

```
./undeploy.sh
oc delete build,bc --all
```

Optionally delete teh project using:
```
oc delete project/jenkins
```

You may want to clean up the PV that was used following undeploying.


