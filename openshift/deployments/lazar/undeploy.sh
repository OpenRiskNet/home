#!/bin/bash

oc delete all,cm,pvc,routes,secrets --selector template=lazar
