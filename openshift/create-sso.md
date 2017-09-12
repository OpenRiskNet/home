# Setting up SSO using Keycloak

[Keycloak](http://www.keycloak.org/) is Red Hat's single sign on solution, being marketed as 
[Red Hat SSO](https://access.redhat.com/products/red-hat-single-sign-on).

Information on running this in OpenShift can be found in these locations:

* Blog/video demonstrating how to set this up [here](https://blog.openshift.com/openshift-commons-briefing-35-sso-best-practices-keycloak-integration-openshift/)
* Documentation for SSO on OpenShift Enterprise [here](https://docs.openshift.com/enterprise/3.1/using_images/xpaas_images/sso.html)
* Documentation in Red Hat customer portal on installing SSO on OpenShift [here](https://access.redhat.com/documentation/en-us/red_hat_jboss_middleware_for_openshift/3/html-single/red_hat_jboss_sso_for_openshift/)
* Official Red Hat customer templates [here](https://github.com/jboss-openshift/application-templates)
* Image streams and templates from another Red Hat project [here](https://github.com/openshift/openshift-ansible/tree/master/roles/openshift_examples/files/examples)

This recipe describes how to get SSO running on OpenShift Origin. It uses an approach that combines information
from several of the resources listed above.

**IMPORTANT**: this did not work using Minishift on Mac because of some problem with Docker for Mac. 
Until this is resolved you should do it using OpenShift origin running on a Linux host. This can be done
using the [openshift_centos recipe](openshift_centos.md).


## Install image streams and templates

Clone the git repo containing the image stream and template definitions:
```
mkdir git
cd git
git clone https://github.com/openshift/openshift-ansible.git
cd
```

Login as `system:admin`:
```
oc login -u system:admin
```

Install the standard image streams (if not already loaded):
```
oc create -f git/openshift-ansible/roles/openshift_examples/files/examples/v3.6/image-streams/image-streams-centos7.json -n openshift
```

Install the xpaas images streams which include those needed for SSO:
```
oc create -f git/openshift-ansible/roles/openshift_examples/files/examples/v3.6/xpaas-streams/jboss-image-streams.json -n openshift
```

Install the database templates:
```
oc create -f git/openshift-ansible/roles/openshift_examples/files/examples/v3.6/db-templates -n openshift
```

Install the quickstart templates:
```
oc create -f git/openshift-ansible/roles/openshift_examples/files/examples/v3.6/quickstart-templates -n openshift
```

## Generate certificates

At various points here you will be prompted for passwords. Make a note of what you specified.
You need a full JDK installed to have the keytool tool. If you don't already have this do:

```
yum install -y java-1.8.0-openjdk
```

Generate a CA certificate:
```
openssl req -new -newkey rsa:4096 -x509 -keyout xpaas.key -out xpaas.crt -days 365 -subj "/CN=xpaas-sso-demo.ca"
```

Generate a Certificate for the SSL keystore:
```
keytool -genkeypair -keyalg RSA -keysize 2048 -dname "CN=secure-sso-sso-app-demo.openshift32.example.com" -alias sso-https-key -keystore sso-https.jks
```

Generate a Certificate Sign Request for the SSL keystore:
```
keytool -certreq -keyalg rsa -alias sso-https-key -keystore sso-https.jks -file sso.csr
```

Sign the Certificate Sign Request with the CA certificate:
```
openssl x509 -req -CA xpaas.crt -CAkey xpaas.key -in sso.csr -out sso.crt -days 365 -CAcreateserial
```

Import the CA into the SSL keystore:
```
keytool -import -file xpaas.crt -alias xpaas.ca -keystore sso-https.jks
```

Import the signed Certificate Sign Request into the SSL keystore:
```
keytool -import -file sso.crt -alias sso-https-key -keystore sso-https.jks
```

Import the CA into a new truststore keystore:
```
keytool -import -file xpaas.crt -alias xpaas.ca -keystore truststore.jks
```

Generate a secure key for the JGroups keystore:
```
keytool -genseckey -alias jgroups -storetype JCEKS -keystore jgroups.jceks
```

## Setup Openshift

Login and create project for this work:
```
oc login -u system:admin
oc new-project sso-app-demo
```

Create service account and add view role to that account:

```
oc create serviceaccount sso-service-account
oc policy add-role-to-user view system:serviceaccount:sso-app-demo:sso-service-account
```

Create secrets and link those to the service account:
```
oc secret new sso-jgroup-secret jgroups.jceks
oc secret new sso-ssl-secret sso-https.jks truststore.jks
oc secrets link sso-service-account sso-jgroup-secret sso-ssl-secret
```

## Deploy the template

Depending on the parameters used above you will need to update some of the parameters specified here,
notably the passwords (replace 'password' with whatever you used).
May of the values specified below are actually default values so do not actually need to be specified
as parameters, but are shown for completeness.
In particular you might want to change:
* SSO_SERVICE_USERNAME/SSO_SERVICE_PASSWORD - this is the account applications can use to register themselves with Keycloak.
* SSO_ADMIN_USERNAME/SSO_ADMIN_PASSWORD - this is the admin account that you will use to log in to Keycloak once it running.

For now this example uses the basic sso71-https template that uses an in-memory database for persistence.

This template is loaded from the GitHub checkout (using the -f argument to oc process).
Those templates can alternatively be loaded into the openshift project as described earlier.


```
oc process -f git/openshift-ansible/roles/openshift_examples/files/examples/v3.6/xpaas-templates/sso71-postgresql-persistent.json\
 -p APPLICATION_NAME=sso\
 -p HTTPS_SECRET=sso-ssl-secret\
 -p HTTPS_PASSWORD=password\
 -p HTTPS_KEYSTORE=sso-https.jks\
 -p JGROUPS_ENCRYPT_KEYSTORE=jgroups.jceks\
 -p JGROUPS_ENCRYPT_PASSWORD=password\
 -p JGROUPS_ENCRYPT_SECRET=sso-jgroup-secret\
 -p SERVICE_ACCOUNT_NAME=sso-service-account\
 -p SSO_REALM=demorealm\
 -p SSO_SERVICE_USERNAME=manager\
 -p SSO_SERVICE_PASSWORD=password\
 -p SSO_ADMIN_USERNAME=admin\
 -p SSO_ADMIN_PASSWORD=password\
 -p SSO_TRUSTSTORE=truststore.jks\
 -p SSO_TRUSTSTORE_SECRET=sso-ssl-secret\
 -p SSO_TRUSTSTORE_PASSWORD=password\
 | oc create -n sso-app-demo -f -
```

If all goes well you can log into the web console and see the deployment. URLs will be something like:
* Web console - https://34.193.87.117.nip.io:8443/console/
* keycloak - https://secure-sso-sso-app-demo.34.193.87.117.nip.io/auth/

## TODO

This recipe is work in progress. In particular need to:

1. Run with a pre-existing PostgreSQL database
1. Consider removing the http service and route as keycloak only works for https 
1. Avoid using self-signed certificates
1. Show how to create an application that uses SSO
