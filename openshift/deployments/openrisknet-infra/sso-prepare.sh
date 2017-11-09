#!/bin/bash
#

oc login $OC_HOST -u $OC_ADMIN

# First make sure the image streams are loaded using:
# oc create -f $HOME/git/openshift/openshift-ansible/roles/openshift_examples/files/examples/v3.6/xpaas-streams/jboss-image-streams.json -n openshift

# create serice account and define permissions
oc create serviceaccount sso-service-account
oc policy add-role-to-user view system:serviceaccount:openrisknet-infra:sso-service-account
