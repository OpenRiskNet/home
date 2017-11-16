# Deploy a more realistic application from a template

## Introduction

This recipe builds and deploys a more realistic application from a template. The app is provided by OpenShift and is a Python/Django app
that uses a PostgreSQL database The template defines both aspects of the application, as well as the services and routes that allow the 
app to be accesed from the outside. As such it is a reasonably realistic example of an application that could be deployed to an 
OpenRiskNet (ORN) Virtual Research Environemnt (VRE). 

In this case the template is already present within the OpenShift environment (e.g. corresponding to one of the ORN "default" apps that 
would be available by default whenever you created a new VRE) but alternatively the template could be defined externally (e.g. in GitHub) 
and loaded from there (e.g. corresponding to a non-official ORN app that could be added to a VRE).

See [OpenShift/Templates](https://github.com/openshift/django-ex/tree/master/openshift/templates).

## Deploy

You should be able to do this with any Openshift environment, including Minishift. 

Login
```sh
$ oc login -u developer
```

Then, either join an existing project...
```sh
$ oc project development
```

Or create a new one...
```sh
$ oc new-project development
```

>   The `django-psql` template defines resources needed to develop a
    Django based application, including a build configuration, application
    deployment configuration, and database deployment configuration.
    The database is stored in **non-persistent storage**, so this configuration
    should be used for experimental purposes only.

Deploy the templated application:
```sh
$ oc new-app --template="openshift/django-psql-example"
[...]
--> Success
    Build scheduled, use 'oc logs -f bc/django-psql' to track its progress.
    Run 'oc status' to view your app.
```

It takes a few mins to build and deploy, you can use `oc status` to review its
progress. Once done you will see the app in the web console and can connect to it.
You will see pods for the Postgres database and the Django app.

Alternatively, to load the same app from an external definition try this:
```sh
$ oc new-app -f https://raw.githubusercontent.com/openshift/library/master/official/django/templates/django-psql-example.json
[...]
--> Success
    Build scheduled, use 'oc logs -f bc/django-psql-example' to track its progress.
    Run 'oc status' to view your app.
```

## Delete app

Once you are finished with the app and want to remove it do this:
```sh
$ oc delete all -l app=django-psql-example
```

## Persistent volume template
An alternative template (`"openshift/django-psql-persistent"`) is available.
Unless you're running minishift, you will need to have arranged for some
persistent volumes on your server.

See the [Creating Persistent Volumes](creating-persistent-volumes.md) recipe.

## Writing templates

An example of how to write OpenShift templates for an app can be found here:
https://github.com/OpenRiskNet/example-java-servlet/tree/master/openshift/templates
