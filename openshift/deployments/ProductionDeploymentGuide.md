# Guide for deploying production services

So you have managed to deploy your apps and/or services, hopefully by means of creating some templates that
allow simple deployment and undeployment. So are you done?

NO, certainly not. OpenRiskNet needs services to be of production quality, so that third parties will find
them easy to deploy, and will satisfy strict security requirements. Think of this as needing to have your
services at a state that a security concious pharmaceutical company will be willing to us.

Here are some guidelines that should be handled to get to this state.

## Container user.

Many containers still run as the root user. This is bad as it introduces potential security risks.
Better to run as a specific non-privileged user. This is still not ideal as there is potential 
'leak through' of user processes between containers.

Best is to allow your container to run as an arbitrarily assigned user. This is the default in OpenShift and
means that your container has to be able to run as any user ID and you do not know in advance what that user 
ID will be.

Sometimes this is not practical, or even possible, so its OK to fall back to run as a dedicated non-privileged
user, but this requires the settings in your project to be changed to allow this. 
Avoid running as the root user unless that is absolutely necessary, and that should hardly ever really be needed.

AIM: your containers can be run without the need to modify the default security settings.

## Routes should run over HTTPS

The expectation nowadays is that HTTPS should be used for all traffic and that all certificates should be signed by 
a trusted CA. Use of plain HTTP or self-signed certificates is frowned on.

The [ACME Controller](acme-controller) tool that is expected to be deployed to any ORN VRE makes this very simple to 
achieve. All that is needed is to add this annotation to your route and [Let's Encrypt](https://letsencrypt.org/) 
certificates will be generated and automatically renewed for your routes.
```
metadata:
  annotations:
    kubernetes.io/tls-acme: "true"
``` 
As a guide its best to set this value of this annotation to `false` while you are setting things up and then switch 
it to `true` when you are finished as Let's Encrypt has fairly strict quotas on the number of certificates that 
can be generated and its easy to exceed this when testing.

## Availability

### Publish your application

Let users know that your application is available for use.
On the currnet ORN production site this involved adding a link to your app (the public routes) in this 
[landing page](https://home.prod.openrisknet.org/).

To do this edit the `index.html` in this [GitHub repo](https://github.com/OpenRiskNet/landing_page).
Committing a change to this repo will result in the page automatically being redeployed a few minutes 
later.

## Service discoverability
Make your services discoverable by the ORN Service Registry.

TODO: describe how to do this once it's working.

## Health checks
Make sure your pods have health checks.

A simple `http://pod.ip/ping` returning a 200 response is usually sufficient.
This allows readiness and liveness checks to be described in your deployment and allows K8S to better
manage your pods (e.g. restart if they become unresponsive).

TODO - describe this further.

## Define resource limits

Define limits for CPU and memory for your pods. See [here](https://docs.openshift.org/3.7/dev_guide/compute_resources.html) 
for more details.

This allows K8S to better schedule pods on the cluster and to kill misbehaving pods.

TODO - describe this further.

## Authentication

Add your application to the OpenRiskNet Realm in Keycloak so that users get a good Single Sign On experience. 

As and example for automatically doing this as part of deployment see the 
[Squonk app](https://github.com/InformaticsMatters/squonk/blob/openshift/openshift/templates/README.md) 
deployment guide.

## Consider use of Infrastructure components

An ORN VRE provides a number of `infrastructure` components. If your application provides these themselves consider
switching to using these so that you can avoid needing to manage them yourself.

The current infrastructure components are:

* PostgreSQL database
* RabbitMQ message queue
* Keycloak for SSO (Red Hat SSO)

If you see you are providing something that could be better handled as an infrastructure component (e.g. a differnt type
of database) then work with us to make this happen. 

## Deployability

Managers of other VREs will want to deploy your application. Make this easy by adding it to the 
[OpenShift Service Catalog](https://docs.openshift.org/latest/architecture/service_catalog/index.html)
(not to be confused with the OpenRiskNet Registry).

If you have are using a Template to deploy you are probably half way there already and can use the 
[Template Service Broker](https://docs.openshift.org/latest/architecture/service_catalog/template_service_broker.html).

More complex deployments can use 
[Ansible Playbook Bundles](https://docs.openshift.org/latest/apb_devel/index.html) with the 
[Ansible Service Broker](https://docs.openshift.org/latest/architecture/service_catalog/ansible_service_broker.html).
 
TODO - describe this further. 

## Continuous delivery

You should aim to have your application automatically re-deployed when it is updated.
There are several approaches, but the 2 most common may be:

1. update whenever a new Docker image is pushed to Docker Hub.
1. Rebuild and deploy when updated code is pushed to GitHub.

TODO - describe this further.


