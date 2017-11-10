#!/bin/bash

set -e

./validate.sh

oc adm policy remove-cluster-role-from-user acme-controller system:serviceaccount:openshift-acme:default
oc delete clusterrole/acme-controller
oc delete all -l app=acme-controller
