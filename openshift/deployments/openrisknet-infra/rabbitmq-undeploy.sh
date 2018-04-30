#!/usr/bin/env bash

set -e

oc login $OC_MASTER_URL -u $OC_ADMIN > /dev/null
oc project -q $OC_INFRA_PROJECT

set +e

oc delete all,cm,pvc,secrets --selector template=rabbitmq

