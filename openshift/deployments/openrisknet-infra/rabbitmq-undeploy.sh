#!/usr/bin/env bash

set -e

../validate.sh

set +e

oc delete all,cm,pvc,secrets --selector template=rabbitmq
