# Deploying Jenkins and running pipelines

## Introduction

A template provided with Openshift illustrates how Jenkisn can be used within Openshift.
Its useful to look at this to get an idea of how powerful things can be set up in an easy way.

## Deployment

```sh
oc new-app jenkins-pipeline-example
```

Then go to the web console and look at Jenkins being deployed.
When that's done deploy a sample pipeline and watch that progress in the web console:
```sh
oc start-build sample-pipeline
```
