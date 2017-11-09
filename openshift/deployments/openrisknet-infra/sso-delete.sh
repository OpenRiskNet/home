#!/bin/bash
#

oc login $OC_HOST -u $OC_ADMIN

oc delete all -l application=sso
