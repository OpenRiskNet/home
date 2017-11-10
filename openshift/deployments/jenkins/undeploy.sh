#!/bin/bash
#

set -e

./validate.sh

oc delete all,pvc -l app=jenkins-persistent
oc delete all -l app=nodejs-helloworld-sample
oc delete serviceaccount/jenkins
oc delete rolebinding/jenkins_edit

echo "Jenkins is undeployed. Builds have not been removed. You can delete them using 'oc delete build,bc --all'"
echo "Delete the jenkins project if you want everything removed"
