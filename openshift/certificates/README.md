# Handling certificates for routes

**NOTE:** This is work in progress. Details may change as may the recommended approaches.

## Background

Certificate management for any application is a tricky, but important, aspect that has to be handled. 
The problem can be avoided by not securing the routes (running with just HTTP on port 80) and this 
may be OK for your needs, but in today's world a professional application is expected to use HTTPS,
but nothing scares users more that the dreaded "This site is not secure" page that you get when 
you access a site using HTTPS but the certificate is not valid.

We will will be using **Let's Encrypt** certificates that are free to obtain and trusted by most browsers.
Information can be obtained [here](https://letsencrypt.org/).

A key aspect of Let's Encrypt is that the process of generating and renewing certificates is designed to
be automated. That's why they only make their certificates last 3 months so that you pretty well have to
automate the certificate renewal process.

## Certificates for OpenShift

There are essentially two categories of certificates required by OpenShift:

### 1. Internal use

These secure the OpenShift infrastructure internally e.g. the communications with the master node, docker repository,  etcd.
This traffic is not public facing and OpenShift can be its own certification authority (CA) and does not
need a chain of trust to a public CA.

>   The OpenShift Ansible installer provides mechanisms for creating and maintaining these certificates.
    See [here](https://docs.openshift.org/latest/install_config/certificate_customization.html)
    and [here](https://docs.openshift.org/latest/install_config/redeploying_certificates.html)
    for details. Currently this document does not cover this aspect. TODO - describe this.

### 2. External use

OpenShift **Routes** allow **Services** to be accessed from the outside through HTTP or HTTPS.
As it is these routes that end users will be accessing it is important that these routes use certificates
that are trusted by a recognised CA such as Let's Encrypt and that these certificates are actively
managed to ensure they do not expire. This document currently just describes how to handle these public routes.

## Public Routes

### OpenShift ACME

To handle the public facing routes we use 
[OpenShift ACME](https://github.com/tnozicka/openshift-acme) that provides a Kubernetes
controller that you deploy to your OpenShift cluster that actively manages the certificates for public 
facing routes.

>   Note: the ACME part of the name comes from the "ACME challenge"
    that is part of obtaining Let's Encrypt certificates.

In short it works like this:

1. Deploy OpenShift ACME to OpenShift so that it is permanantly running.
1. Deploy your route to OpenShift with a `kubernetes.io/tls-acme: "true"` annotation.
1. OpenShift ACME then handles obtaining a certificate for you and updating it before it expires.

For a bit more detail of what is happening when you deploy a route with that annotation, here is
an abreviated description of what happens:

1. OpenShift ACME detects that the new route contains the annotation and kicks into action.
1. OpenShift ACME generates a Let's Encrypt certificate for the specified host for the route.
1. OpenShift ACME modifies the route definition to enable TLS and copies the certificate inline into the route definition.
1. OpenShift ACME also creates a secret for the certificate so that it can be used for other purposes (this secret is not currently used directly by the route).
1. OpenShift ACME updates the certificate before it expires and updates the route definition and secrets.

The net effect of this is that it is very simple to get your routes secured using TLS.
You don't need to do anything other than add the appropriate annotation to your route definition.

## Deploy OpenShift ACME

Deploy OpenShift using any of the described approaches. The instance must be publically accessible and must have a 
publically resolvable hostname.

Clone the OpenShift ACME project from GitHub:
```
$ git clone https://github.com/tnozicka/openshift-acme.git
```
Alternatively the files can be accessed directly from GitHub.

Perform these steps as system:admin or equivalent user.

Login and create a new project for OpenShift ACME. You wil need administrator
privileges. Here we're loggin in as `system:admin` but it would be more
sensible to grant privileges to specific users.
 
```
$ oc login -u system:admin
$ oc new-project acme-controller
```

Create a cluster role named `acme-controller` that is needed to grant extra privs to the acme controller as
it needs to access assets across all projects. 
```
$ oc create -f openshift-acme/deploy/clusterrole.yaml
clusterrole "acme-controller" created
```

Grant that acme-controller role to the service account for your project. 
```
$ oc adm policy add-cluster-role-to-user acme-controller system:serviceaccount:acme-controller:default
cluster role "acme-controller" added: "system:serviceaccount:acme-controller:default"
```
Adjust `serviceaccount:acme-controller` if you did not name the project `acme-controller`.

Deploy the deployment config and service. There are two implementations, one that 
points to the live Let's Encrypt servers, a second that point to their staging servers.
The staging version generates real certificates but they are not trusted, and do not count to the allowance for your server so
is suitable for testing.

To deploy the staging version:
```
$ oc create -f openshift-acme/deploy/deploymentconfig-letsencrypt-staging.yaml -f openshift-acme/deploy/service.yaml
deploymentconfig "acme-controller" created
service "acme-controller" created
```
To deploy the live version:
```
$ oc create -f openshift-acme/deploy/deploymentconfig-letsencrypt-live.yaml -f openshift-acme/deploy/service.yaml
deploymentconfig "acme-controller" created
service "acme-controller" created
```

>   Note: both the deployment config and the service need to be deployed together.

Check everything is running OK, specifically that `rc/acme-controller-1`
is in a `Ready` state:
```
$ oc get all
NAME                 REVISION   DESIRED   CURRENT   TRIGGERED BY
dc/acme-controller   1          1         1         config

NAME                   DESIRED   CURRENT   READY     AGE
rc/acme-controller-1   1         1         1         1m

NAME                  CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
svc/acme-controller   172.30.160.170   <none>        80/TCP    1m

NAME                         READY     STATUS    RESTARTS   AGE
po/acme-controller-1-9x8n6   1/1       Running   0          1m
```

## Deploy example app and secure

We will use the NodeJS example that comes with OpenShift, but other examples should also work.
This example has a route definition but it only uses HTTP. We will see that once the acme controller is running
it is very simple to add TLS to the route.

1. From the OpenShift console login as a normal user and create a new project for your app.  
1. Use the **Add to project** function and choose the **JavaScript** section from the **Browse Catalog**.
1. Select the **Node.js** section and choose the **nodejs-ex.git** example (link present in the page you see).
1. Deploy the app.

After a while you will see the app's **pod** and you will notice that it has a basic HTTP route.

1. Navigate to the route definition by clicking on the route's `Name`.
1. In `Actions` select `Edit YAML`. You will notice that there is nothing there releated to TLS or HTTPS.
1. Add this extra annotation to the metadata section at the top: `kubernetes.io/tls-acme: 'true'` and click **Save**.
   (note: the quotes around the `true` are necessary).
1. After a few seconds you will notice that the route description now has a TLS Settings section.
1. If you edit the YAML again you will see a tls section containing the certificate and key.
1. The route is now secured with TLS. Try it in your browser (if using the staging implementation the certificates will not be trusted, but they are present).

If you look at the logs of the controller pod you will see something like this:
```
$ oc logs acme-controller-1-9x8n6
2017-09-06T08:07:08.416332068Z   INFO Starting controller
2017-09-06T08:07:08.416475218Z   INFO ACME server url is 'https://acme-staging.api.letsencrypt.org/directory'
ERROR: logging before flag.Parse: W0906 08:07:08.416505       1 client_config.go:481] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
2017-09-06T08:07:08.417597362Z   INFO AcmeController bootstraping DB
2017-09-06T08:07:08.417626859Z  TRACE AcmeController bootstraping DB finished duration=38.890418ms start=2017-09-06T08:07:08.417627122Z end=2017-09-06T08:07:08.456517540Z
2017-09-06T08:07:08.456563326Z   INFO AcmeController initializing
2017-09-06T08:07:08.456577806Z   INFO AcmeController started
2017-09-06T08:07:08.456812408Z   INFO Http-01: server listening on http://[::]:5000/
2017-09-06T08:07:08.459772010Z   INFO RouteController initializing
2017-09-06T08:07:08.459807636Z   INFO RouteController started
2017-09-06T08:07:08.459819117Z   INFO RouteController: watching namespace ''
2017-09-06T08:31:37.602823193Z   INFO Creating new account in namespace example-node-project
2017-09-06T08:31:37.602853729Z  TRACE Creating new account in namespace example-node-project finished duration=4.131497088s start=2017-09-06T08:31:37.602854013Z end=2017-09-06T08:31:41.734351101Z
2017-09-06T08:31:41.734476268Z   INFO Obtaining certificate start
2017-09-06T08:31:41.734489524Z   INFO Obtaining certificate
2017-09-06T08:31:53.617176225Z   INFO finished validating domains
2017-09-06T08:31:41.734506747Z  TRACE acme.Client ObtainCertificate duration=13.80217099s start=2017-09-06T08:31:41.734507027Z end=2017-09-06T08:31:55.536678017Z
2017-09-06T08:31:55.539789538Z   INFO Creating new secret 'acme.nodejs-ex' in namespace '' for route 'nodejs-ex'
2017-09-06T08:31:55.545880535Z   INFO Updating route 'nodejs-ex' in namespace 'example-node-project'
2017-09-06T08:31:55.550741956Z   INFO Route 'nodejs-ex' in namespace 'example-node-project' UPDATED.
```

Notice the bit at the bottom relating to managing the certificate. Also, that a secret named 'acme.nodejs-ex' has been created.
If you look at this you will see the certificate and key.

## Manging your own routes

Once OpenShift ACME is running deploying secured routes is very simple. Just create a basic route definition as if you were 
only using HTTP and add the openshift.io/host.generated: "true"` annotation to the metadata section and all ther rest will 
happen by magic.
If OpenShift ACME is not running on your system no harm will be done by adding that annotation, just that your
route will just run using HTTP.

## TODOs

* Investigate how to specify other TLS settings when using OpensShift ACME.
* Work out how to specify time range for certificate renewal with OpensShift ACME.
* Confirm that certificates get renewed by OpensShift ACME as expected.
* Establish how to secure master API and Docker registry using OpensShift ACME.
* Add information for managing internal certificates (using Ansible installer).