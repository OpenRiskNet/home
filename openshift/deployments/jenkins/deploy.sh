#!/bin/bash
#

set -e 

./validate.sh

oc new-app -f jenkins-template.yaml -p ROUTE_HOSTNAME=jenkins.$OC_ROUTES_BASENAME
oc new-app -f https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/application-template.json

echo "Jenkins deployed. Access it at https://jenkins.$OC_ROUTES_BASENAME"
