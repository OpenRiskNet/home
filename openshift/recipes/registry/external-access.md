# Setting up the OpenShift container registry for external access

By default the openshift registry is set up with a public route, but this uses `passthrough` termination and the registry service uses a 
certificate that does not include the public hostname of the registry. Hence the registry can't really be used externally.

This recipe describes how to change this and then how to access the registry.

## Set up for external access

Assumptions:

* you are an admin for the `default` proejct where the registry resides
* You cluster is using Let's Encrypt certificates handled by ACME Controller (see [here](../certificates/) for how to do this) 

You need to edit the definition of the route for the registry. By default it uses `passthrough` termination. Instead you need to 
change this to `reencrypt` and tell ACME Contoller to generate certificates.

1. Edit the YAML for the `docker-registry` route in the `default` project. Use `oc edit route/docker-registry` from the CLI or 
use the web console.
2. Change the `termination` property to `reencrypt`.
3. Add this annotation: `kubernetes.io/tls-acme: 'true'`.
4. Save the YAML definition.

The content will look a bit like this (not all the content is shown):

```
apiVersion: v1
kind: Route
metadata:
  annotations:
    kubernetes.io/tls-acme: 'true'
    openshift.io/host.generated: 'true'
  name: docker-registry
  namespace: default
spec:
  host: docker-registry-default.prod.openrisknet.org
  tls:
    termination: reencrypt
```

A few seconds later the certicates should have been generated. Look at the YAML file again to check this. If not look in the logs of 
the ACME controller pod for any errors.

Now the registry is using a trusted TLS certificate and you can access it from outside the cluster.

## Accessing the registry

Assumptions:

* You have access to the cluster from your computer.
* You have Docker and the oc client installed on your computer.
* You have a suitable account on the OpenShift cluster.

1. Find out your access token (either by logging in to the web console and using the `Copy Login Command` option from the menu in the 
top right corner or by logging in using the CLI and then issuing `oc whoami --show-token`
2. Login to the docker registry using `docker login -u <username> -p <token> <registry-location>`. 
Change \<username\>, \<token\> and \<registry-location\> accordingly. For the ORN prod site the registry-location will be 
`docker-registry-default.prod.openrisknet.org`.
3. Perform docker operations. e.g. `docker pull docker-registry-default.prod.openrisknet.org:jupyter-builds/miniconda3:latest`


