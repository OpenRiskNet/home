#!/bin/bash

set -e

source setenv.sh

oc process -f os-jguweka-template.yaml \
  -p IMAGE_TAG=$IMAGE_TAG \
  -p ROUTE_NAME=$ROUTE_NAME \
  -p ROUTES_BASENAME=$ROUTES_BASENAME \
| oc create -f -
