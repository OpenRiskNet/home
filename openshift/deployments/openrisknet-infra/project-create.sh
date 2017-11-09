#!/bin/bash
#
# First make sure you have a suitable PV to support the PVC that postgres claims

oc login $OC_HOST -u $OC_ADMIN
oc new-project openrisknet-infra
 
