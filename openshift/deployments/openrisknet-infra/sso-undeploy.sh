#!/bin/bash
#

set -e

./validate.sh

oc delete all -l application=sso
