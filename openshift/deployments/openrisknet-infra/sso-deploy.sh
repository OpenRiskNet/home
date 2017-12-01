#!/bin/bash
#

set -e

./validate.sh

oc process -f sso-template.yaml\
 -p SSO_REALM=openrisknet\
 -p HTTPS_PASSWORD=$OC_CERTS_PASSWORD\
 -p JGROUPS_ENCRYPT_PASSWORD=$OC_CERTS_PASSWORD\
 -p SSO_TRUSTSTORE=truststore.jks\
 -p SSO_TRUSTSTORE_PASSWORD=$OC_CERTS_PASSWORD\
 -p HOSTNAME_HTTPS=sso.${OC_ROUTES_BASENAME}\
 | oc create -f -
