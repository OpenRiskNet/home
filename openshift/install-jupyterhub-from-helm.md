This document outlines how to install a vanilla Kubernetes Helm chart into an OpenShift cluster. It was created during the Uppsala Workshop 
in September of 2017 using OpenShift 3.6 and the Jupyterhub Helm Chart version 0.4.

## Setup Helm for OpenShift

Helm is a similar concept to OpenShift Templates in plain Kubernetes. Since Kubernetes has a very big userbase, it is nice to be able to 
make use of this big catalouge of so called Helm Charts for various applications. The major difference between OpenShift templates and 
Helm charts as far as I can see is that Templates are easier to integrate with OpenShifts fine grained permission model. Helm Charts need
Administrator credentials in OpenShift to be installed without problems.

* Follow this tutorial to get Helm installed in your cluster: https://blog.openshift.com/deploy-helm-charts-minishifts-openshift-local-development/
* Then follow this tutorial up to step 5 to setup the permissions for the jupyterhub namespace correctly: https://webcache.googleusercontent.com/search?q=cache:1vj_2SkW9wMJ:https://github.com/jupyterhub/helm-chart/issues/26+&cd=1&hl=de&ct=clnk&gl=se&client=firefox-b-ab
* Finally, follow the steps here to install the actual JupyterHub Chart: https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub.html
