#!/bin/bash

set -e

./validate.sh


oc create\
  -f https://raw.githubusercontent.com/tnozicka/openshift-acme/master/deploy/letsencrypt-live/cluster-wide/clusterrole.yaml\
  -f https://raw.githubusercontent.com/tnozicka/openshift-acme/master/deploy/letsencrypt-live/cluster-wide/serviceaccount.yaml\
  -f https://raw.githubusercontent.com/tnozicka/openshift-acme/master/deploy/letsencrypt-live/cluster-wide/imagestream.yaml\
  -f https://raw.githubusercontent.com/tnozicka/openshift-acme/master/deploy/letsencrypt-live/cluster-wide/deployment.yaml

oc adm policy add-cluster-role-to-user openshift-acme -z openshift-acme
