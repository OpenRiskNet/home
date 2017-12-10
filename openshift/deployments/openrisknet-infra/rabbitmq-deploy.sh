#!/bin/bash
#

set -e pipefail

../validate.sh


# Deploy core RabbitMQ service
oc process -p INFRA_NAMESPACE=$OC_INFRA_PROJECT\
  -p RABBITMQ_HOST=rabbitmq.${OC_INFRA_PROJECT}.svc\
  -f rabbitmq.yaml | oc create -f -
