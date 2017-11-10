#!/bin/bash
#

set -e

./validate.sh

set +x

# delete serice account and permissions
oc policy remove-role-from-user view system:serviceaccount:openrisknet-infra:sso-service-account
oc delete serviceaccount/sso-service-account
