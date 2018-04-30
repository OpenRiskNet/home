#!/bin/bash
#

set -e

oc login $OC_MASTER_URL -u $OC_ADMIN > /dev/null
oc project -q $OC_INFRA_PROJECT

set +e

# Deploy core RabbitMQ service
oc process -p INFRA_NAMESPACE=$OC_INFRA_PROJECT\
  -p RABBITMQ_HOST=rabbitmq.${OC_INFRA_PROJECT}.svc\
  -f rabbitmq.yaml | oc create -f -

