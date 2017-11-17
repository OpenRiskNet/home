#!/bin/bash
#

set -e

./validate.sh

oc process -f sso-template.yaml\
 -p SSO_REALM=openrisknet\
 -p HTTPS_PASSWORD=password\
 -p JGROUPS_ENCRYPT_PASSWORD=password\
 -p SSO_SERVICE_PASSWORD=password\
 -p SSO_ADMIN_PASSWORD=password\
 -p SSO_TRUSTSTORE=truststore.jks\
 -p SSO_TRUSTSTORE_PASSWORD=password\
 -p HOSTNAME_HTTPS=sso.${OC_ROUTES_BASENAME}\
 | oc create -f -
