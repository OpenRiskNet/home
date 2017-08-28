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
This might take a little while to build. In the meantime, we will also be needing a Postgresql database:
```
$ oc new-app -e POSTGRESQL_ADMIN_PASSWORD=foo \
             -e POSTGRESQL_USER=keycloak \
             -e POSTGRESQL_PASSWORD=keycloak \
             -e POSTGRESQL_DATABASE=keycloak \
             centos/postgresql-95-centos7 --name postgres-95
```

Then (once the Keycloak build is completed, to see progress check **Builds** -> **Builds** in the left menu) we deploy the Keycloak build, from UI: **Add to Project**, **Deploy Image** and find it in Image Stream tag.
For me it was under: `myproject / keycloak : latest`

We need to set some environment variables for `keycloak`:
```
POSTGRES_PORT_5432_TCP_ADDR  postgres-95.myproject.svc
POSTGRES_PASSWORD keycloak
```

### Create route for Keycloak
Under **Applications** in the left menu select **Routes** and then **Create Route** in the upper right corner. 

Name your route, _e.g._ keycloakroute, make sure that the service is set to your keycloak service and click **Create**

## Getting a sample Django project and modify it to use Keycloak for authentication
OpenShift comes with a sample Django template and [repository](https://github.com/openshift/django-ex). 
We are going to need to edit the Django project so start by cloning it into your own Github account and 
check it out to your machine. I have done so and my [repository](https://github.com/jonalv/django-ex)
contains a version of _django-ex_ with all the changes described in this text.


