#!/bin/bash
#

set -e

./validate.sh

# create serice account and define permissions
oc create serviceaccount sso-service-account
oc policy add-role-to-user view system:serviceaccount:openrisknet-infra:sso-service-account
