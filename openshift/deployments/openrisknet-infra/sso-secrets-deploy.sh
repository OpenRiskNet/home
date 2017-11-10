#!/bin/bash

set -e

./validate.sh


oc secret new sso-jgroup-secret certs/jgroups.jceks
oc secret new sso-ssl-secret certs/sso-https.jks certs/truststore.jks
oc secrets link sso-service-account sso-jgroup-secret sso-ssl-secret
