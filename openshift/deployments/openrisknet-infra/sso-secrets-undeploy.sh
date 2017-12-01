#!/bin/bash

set -e

./validate.sh

set +e

oc delete secret/sso-jgroup-secret
oc delete secret/sso-ssl-secret

