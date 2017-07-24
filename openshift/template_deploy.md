# Deploy a more realistic application from a template

## Introduction

This recipe builds and deploys a more realistic application from a template. The app is provided by OpenShift and is a Python/Django app
that uses a PostgreSQL database The template defines both aspects of the application, as well as the services and routes that allow the 
app to be accesed from the outside. As such it is a reasonably realistic example of an application that could be deployed to an 
OpenRiskNet (ORN) Virtual Research Environemnt (VRE). 

In this case the template is already present within the OpenShift environment (e.g. corresponding to one of the ORN "default" apps that 
would be available by default whenever you created a new VRE) but alternatively the template could be defined externally (e.g. in GitHub) 
and loaded from there (e.g. corresponding to a non-official ORN app that could be added to a VRE).

## Deploy

You should be able to do this with any Openshift environment, including Minishift. 

Switch to appropriate user and project:
```sh
oc login -u developer1
oc project development
```

Deploy application:
```sh
oc new-app --template=django-psql-persistent
```
It takes a few mins to build and deploy. Once done you will see the app in the web console and can connect to it.
You will see pods for the Postgres database and the Django app.

Alternatively, to load the same app from an external definition try this:
```sh
oc new-app -f https://raw.githubusercontent.com/openshift/library/master/official/django/templates/django-psql-persistent.json
```

## Delete app

If you are finished with this app and want to remove it do this:
```sh
oc delete all -l app=django-psql-persistent
```

## Writing templates

An example of how to write OpenShift templates for an app can be found here:
https://github.com/OpenRiskNet/example-java-servlet/tree/master/openshift/templates
