#!/bin/bash

set -e

source setenv.sh

oc process -f os-jguweka-template.yaml -p ROUTES_BASENAME=$OC_ROUTES_BASENAME | oc create -f -
