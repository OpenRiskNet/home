# Deploy CDK Depict using templates

[This recipe](CDK_depict.md) showed how to build and deploy an app using the web console.
For true autmation and re-use the web console is not the way to go. In this recipe we walk through
how to build and deploy the same application using templates.

Appart from allowing this to be done from the command line, so aiding automation, this approach breaks
the process down into two parts, first a template that allows the CDK Depict application to be built and
pushed to the Docker repository, and second one that deploys the image to an OpenShift environment. 
This way we (OpenRiskNet) can build the application image, but adminstrators of other OpenRiskNet Virtual 
Research Environments can deloy that image to their own environment without having to worry about how to build it.

The underlying process is much the same as when using the web console, but the procedure looks quite different.

## Building the application

For this we need:

1. A build config that pulls the source code and builds the Docker image.
2. An image stream into which the image is pushed once it is built.

We create these from a template that we use to build the build config and image stream definitions.
We assume you have cloned this repository and are in this openshift/cdkdepict directory which contains the
templates.

Create a new project:
```
$ oc new-project cdkdepict
```

Take a look at the template:

```
$ cat build-template.yaml
```
In it you will see the build config and image stream objects. There are parameters for the application name and an
automatically generated secret that is used for the GitHub build trigger. You typically do not need to override these.

Take a look at the processed template:

```
$ oc process -f build-template.yaml -o yaml
```
You will see the defintions of the build config and the image stream.
If you are happy with this deploy the objects.
```
$ oc process -f build-template.yaml | oc create -f -
imagestream "cdkdepict" created
buildconfig "cdkdepict" created
```
A build will be immediately triggered and you can monitor it using `oc status`. After about a minute you will see
something like this:
```
$ oc status
In project cdkdepict on server https://ip-10-0-113-31.eu-west-1.compute.internal:8443

bc/cdkdepict source builds https://github.com/cdk/depict.git#master on openshift/wildfly:10.1
  -> istag/cdkdepict:latest
  build #1 succeeded 20 minutes ago - 89cee5d: Newer beam version (John Mayfield <john@nextmovesoftware.com>)

View details with 'oc describe <resource>/<name>' or list everything with 'oc get all'.
```
All is good. You now have a Docker image that has been built from the source code on GitHub and will be
rebuilt whenever the source code, builder image or configuration is updated.


## Deploying the application

We now deploy the application using the Docker image that we built earlier. To do this we use the deploy-template.yaml template.
Let's look at it:

```sh
$ cat deploy-template.yaml
```

In it you will see definitions for the Replication Controller, the Service and the Route, as well as a small number of parameters
that can be set by the person performing the deployment. Let's look at what the template generates:

```
$ oc process -f deploy-template.yaml -o yaml
```
All looks OK so let's deploy this:

```
$ oc process -f deploy-template.yaml | oc create -f -
replicationcontroller "cdkdepict" created
service "cdkdepict" created
route "cdkdepict" created
```

Go to the web console and look at your app.
If all went well you should see a route defintion along with a link that takes you to the app. 
Click on that link and you should see the CDK Depict application. Huurah!

## Undeploying

To undeploy the app so that you can start again do this:

```
oc delete po,svc,rc,route -l app=cdkdepict
```
This does not delete the Build Config or Image Stream so you do not need to re-create these.

## Notes

The route definition contains the `kubernetes.io/tls-acme: "true"` annotation so you should be able to add TLS support to 
the route using the [OpenShift ACME controller recipe](../certificates/README.md).

The route to the app that is automatically generated is a bit ugly. You can improve this using the APPLICATION_DOMAIN parameter:
```
oc process -f deploy-template.yaml -p APPLICATION_DOMAIN=cdkdepict.mydomain.com | oc create -f -
```

TODO - The template could be improved by using a Deployment rather than a Replication Controller.

The template uses a hard-coded Docker image name, assuming that it has been generated in the same project and default names 
have been used. TODO - add parameters to improve this. 












 