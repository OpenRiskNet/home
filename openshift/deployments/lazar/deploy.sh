#!/bin/bash

set -e
source setenv.sh

echo "IMAGE_TAG set to ${IMAGE_TAG}"
echo "ROUTES_BASENAME set to ${ROUTES_BASENAME}"
echo "ROUTE_NAME set to ${ROUTE_NAME}"
echo "LAZAR_SERVICE_PORT set to ${LAZAR_SERVICE_PORT}"
echo "TLS set to ${TLS}"
echo "CPU limit is set to ${CPU_LIMIT}"
echo "CPU request is set to ${CPU_REQUEST}"
echo "Memory limit is set to ${MEMORY_LIMIT}"
echo "Memory request is set to ${MEMORY_REQUEST}"

oc process -f lazar.yaml \
  -p IMAGE_TAG=$IMAGE_TAG \
  -p ROUTES_BASENAME=$ROUTES_BASENAME \
  -p ROUTE_NAME=$ROUTE_NAME \
  -p LAZAR_SERVICE_PORT=$LAZAR_SERVICE_PORT \
  -p TLS=$TLS \
| oc create -f -
