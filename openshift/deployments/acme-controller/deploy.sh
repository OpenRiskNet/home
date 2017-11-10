#!/bin/bash

set -e

./validate.sh

oc create -f https://raw.githubusercontent.com/tnozicka/openshift-acme/master/deploy/clusterrole.yaml

oc adm policy add-cluster-role-to-user acme-controller system:serviceaccount:acme-controller:default

oc create\
 -f https://raw.githubusercontent.com/tnozicka/openshift-acme/master/deploy/deploymentconfig-letsencrypt-live.yaml\
 -f https://raw.githubusercontent.com/tnozicka/openshift-acme/master/deploy/service.yaml

oc label svc/acme-controller app=acme-controller
