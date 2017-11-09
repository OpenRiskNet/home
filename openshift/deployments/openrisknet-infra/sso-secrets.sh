#!/bin/bash

oc login $OC_HOST -u $OC_ADMIN

oc delete secret/sso-jgroup-secret
oc delete secret/sso-ssl-secret

oc secret new sso-jgroup-secret certs/jgroups.jceks
oc secret new sso-ssl-secret certs/sso-https.jks certs/truststore.jks
oc secrets link sso-service-account sso-jgroup-secret sso-ssl-secret
