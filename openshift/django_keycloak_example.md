# Integrating Keycloak and Python Django on OpenShift
In this recipe we will set up Keycloak authentication for a Python Django project and run it in MiniShift.

## Starting Keycloak service on MiniShift
We create a build from an inline dockerfile:
```
$ oc new-build jboss/keycloak-postgres:latest --name=keycloak --dockerfile='FROM jboss/keycloak-postgres:latest
 
USER root

#Give correct permissions when used in an OpenShift environment.
RUN chown -R jboss:0 $JBOSS_HOME/standalone && \
    chmod -R g+rw $JBOSS_HOME/standalone

USER jboss'
```

## Getting a sample Django project and modify it to use Keycloak for authentication
OpenShift comes with a sample Django template and [repository](https://github.com/openshift/django-ex). 
We are going to need to edit the Django project so start by cloning it into your own Github account and 
check it out to your machine. I have done so and my [repository](https://github.com/jonalv/django-ex)
contains a version of _django-ex_ with all the changes described in this text.


