#!/bin/bash

P='jenkins'

if [ ! $OC_PROJECT == $P ]; then
    echo "ERROR: wrong configuration. Try sourcing setenv.sh"
    exit 1
fi

if [ ! $(oc project -q) == $P ]; then
    echo "ERROR: wrong project. Try 'oc project $P' or 'oc new-project $P'"
    exit 1
fi


if [ ! $OC_ADMIN == $(oc whoami) ]; then
    oc login $OC_HOST -u $OC_ADMIN
fi
