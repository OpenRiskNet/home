#!/bin/bash
#

set -e

./validate.sh

set +e

oc delete all -l application=sso
oc delete secret/sso
oc delete secret/postgresql
oc delete pvc/postgresql-claim
