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

Install the standard image streams:
```
oc create -f git/openshift-ansible/roles/openshift_examples/files/examples/v3.6/image-streams/image-streams-centos7.json -n openshift
```
>   If the streams are already loaded you will see an **Error** detailing the
    stream and telling you that it is **already exists**

Install the xpaas images streams which include those needed for SSO:
```
oc create -f git/openshift-ansible/roles/openshift_examples/files/examples/v3.6/xpaas-streams/jboss-image-streams.json -n openshift
```

Install the database templates:
```
oc create -f git/openshift-ansible/roles/openshift_examples/files/examples/v3.6/db-templates -n openshift
```
>   As with the standard image streams you might again be told **already exists**.

Install the quickstart templates:
```
oc create -f git/openshift-ansible/roles/openshift_examples/files/examples/v3.6/quickstart-templates -n openshift
```
>   As with the standard image streams you might again be told **already exists**.

## Generate certificates

At various points here you will be prompted for passwords. Make a note of what you specified.
You need a full JDK installed to have the Keycloak tool.
If you don't already have this do (as root or using sudo):

```
$ sudo yum install -y java-1.8.0-openjdk.x86_64
```

>   If you use `password` as the password (I know it isn't terribly secure)
    each time you're prompted over the next few commands you will at least be
    able to cut-and-paste the text from the **Deploy template** later in this
    recipe without being forced to make any changes.
    
Generate a CA certificate and provide a passphrase of more than 3 characters:
```
$ sudo openssl req -new -newkey rsa:4096 -x509 \
    -keyout xpaas.key -out xpaas.crt -days 365 \
    -subj "/CN=xpaas-sso-demo.ca"
[...]
writing new private key to 'xpaas.key'
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
```

Generate a Certificate for the SSL keystore and provide passwords of more than
5 characters:
```
$ keytool -genkeypair -keyalg RSA -keysize 2048 \
    -dname "CN=secure-sso-sso-app-demo.openshift32.example.com" \
    -alias sso-https-key -keystore sso-https.jks
Enter keystore password:  
Re-enter new password: 
Enter key password for <sso-https-key>
	(RETURN if same as keystore password):  
```

Generate a Certificate Sign Request for the SSL keystore.
Here you'll be asked to enter the keystore password you entered earlier:
```
$ keytool -certreq -keyalg rsa \
    -alias sso-https-key -keystore sso-https.jks -file sso.csr
Enter keystore password:  
```

Sign the Certificate Sign Request with the CA certificate.
Here you'll need to re-enter the xpaas pass phrase you entered earlier.
```
$ openssl x509 -req -CA xpaas.crt \
    -CAkey xpaas.key -in sso.csr \
    -out sso.crt -days 365 -CAcreateserial
Signature ok
subject=/CN=secure-sso-sso-app-demo.openshift32.example.com
Getting CA Private Key
Enter pass phrase for xpaas.key:
```

Import the CA into the SSL keystore (re-entering your keystore password)
and saying `yes` to `Trust this certificate?`:
```
$ keytool -import -file xpaas.crt \
    -alias xpaas.ca -keystore sso-https.jks
[...]
Trust this certificate? [no]: yes
Certificate was added to keystore
```

Import the signed Certificate Sign Request into the SSL keystore,
again entering your keystore password:
```
$ keytool -import -file sso.crt \
    -alias sso-https-key -keystore sso-https.jks
Enter keystore password:  
Certificate reply was installed in keystore
```

Import the CA into a new truststore keystore,
again, entering your keystore password and confirming that the
certificate can be trusted:
```
$ keytool -import -file xpaas.crt \
    -alias xpaas.ca -keystore truststore.jks
[...]
Trust this certificate? [no]:  yes
Certificate was added to keystore
```

Generate a secure key for the JGroups keystore:
```
$ keytool -genseckey \
    -alias jgroups -storetype JCEKS -keystore jgroups.jceks
Enter keystore password:  
Re-enter new password: 
Enter key password for <jgroups>
	(RETURN if same as keystore password):  
```

## Setup OpenShift

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
notably the passwords (replace `password` with whatever you used).
Many of the values specified below are actually default values so do not actually need to be specified
as parameters, but are shown for completeness.
In particular you might want to change:
* SSO_SERVICE_USERNAME/SSO_SERVICE_PASSWORD - this is the account applications can use to register themselves with Keycloak.
* SSO_ADMIN_USERNAME/SSO_ADMIN_PASSWORD - this is the admin account that you will use to log in to Keycloak once it running.

For now this example uses the basic `sso71-https` template that uses an in-memory database for persistence.

This template is loaded from the GitHub checkout (using the `-f` argument to `oc process`).
Those templates can alternatively be loaded into the openshift project as described earlier.

```
oc process -f git/openshift-ansible/roles/openshift_examples/files/examples/v3.6/xpaas-templates/sso71-https.json\
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

If all goes well you should see successful creation of items:

```
service "sso" created
service "secure-sso" created
route "sso" created
route "secure-sso" created
deploymentconfig "sso" created
```

You can log into the web console and see the deployment.

Use `oc get all` to get information about the deployment and you should
see somthing like this:

```
$ oc get all
[...]
NAME                HOST/PORT                                            PATH      SERVICES     PORT      TERMINATION   WILDCARD
routes/secure-sso   secure-sso-sso-app-demo.abc.informaticsmatters.com             secure-sso   <all>     passthrough   None
routes/sso          sso-sso-app-demo.abc.informaticsmatters.com                    sso          <all>                   None
[...]
```

URLs will be something like:
* Web console - https://abc.informaticsmatters.com:8443/console/
* keycloak - https://secure-sso-sso-app-demo.abc.informaticsmatters.com/auth/

Unless you changes the passqword for the application you shoulld be able
to login to the Single-Sign-On URL using `admin` and `password` as the
username and passwords.

## Using Persistent Volumes

The template used above does not use persistent volumes, so everything will be lost when the pod stops.
For a real environment we need to use a version of the template that handles persistence and provide the
approprite Persistent Volumes. We will use the sso71-postgresql-persistent template that uses a Postgres
database to store the Keycloak data.

First you need to create a Persistent Volume. This can be done in a number of ways, but here we will use a
volume provides by NFS so that the Postgress pod can be run on any node in the cluster (Note: this is not optimal 
for performance). If using a MiniShift environment your should already have Persistent Volumes available and can skip 
this and just run apply the sso71-postgresql-persistent.json template. 

To run this you need a cluster that has NFS provisioned. In your inventory file you need a nfs section:

```
[nfs]
MASTER_HOSTNAME
```
(replace MASTER_HOSTNAME with the actual hostname).

SSH to the master node (assuming this is the one providing the NFSserver) and configure a NFS export that can be used.
As root or sudo:

```
mkdir -p /home/data/keycloak
chmod -R 777 /home/data/keycloak/
```
Now edit /etc/exports.d/persitent-volumes.exports and add a line like this to it:
```
/home/data/keycloak *(rw,root_squash)
```
Restart the NFS server and verify that your new export is present:
```
systemctl restart nfs-server
showmount -e localhost
```

Now define the Persistent volume using that export. Create the definition in the file pv-keycloak.yaml. Adjust the size if not
using the default setting of the VOLUME_CAPACITY parameter for the Keycloak template. 

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: keycloak
spec:
  capacity:
    storage: 512Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: localhost
    path: /home/data/keycloak
```

Create the PV:
```
oc create -f pv-keycloak.yaml
```

Now you can create the keycloak environment as above but using the
`sso71-postgresql-persistent.json` template. Once done check that the
Persitent Volume Claim gets bound to the Persistent Volume you created
and that Keycloak starts correctly.

## TODO

This recipe is work in progress. In particular need to:

1. Run with a pre-existing PostgreSQL database
1. Consider removing the http service and route as keycloak only works for https 
1. Avoid using self-signed certificates
1. Show how to create an application that uses SSO
1. Improve how persistent volumes are handled so that local volumes are used