#!/bin/bash

# for openshift the public hostname master
# for minishift the IP address of the minishift VM. eg. `minishift ip`  
export OC_MASTER_HOSTNAME=prod.openrisknet.org
export OC_ADMIN=admin
export OC_MASTER_URL=https://${OC_MASTER_HOSTNAME}
# change this to the hostname of the infra node hosting the router (which might be the same)
export OC_ROUTES_BASENAME=${OC_MASTER_HOSTNAME}
export KEYCLOAK_SERVER_URL=https://sso.${OC_ROUTES_BASENAME}/auth
export KEYCLOAK_REALM=openrisknet
export KEYCLOAK_LOGOUT_REDIRECT_TO=http://home.${OC_ROUTES_BASENAME}/
export OC_INFRA_PROJECT=openrisknet-infra
export OC_DOMAIN_NAME=novalocal
export OC_NFS_SERVER=xchem-infra.$OC_DOMAIN_NAME



echo "OC_INFRA_PROJECT set to $OC_INFRA_PROJECT"
echo "OC_MASTER_HOSTNAME set to $OC_MASTER_HOSTNAME"
echo "OC_ROUTES_BASENAME set to $OC_ROUTES_BASENAME"
echo "OC_ADMIN set to $OC_ADMIN"
echo "OC_NFS_SERVER set to $OC_NFS_SERVER"
echo "KEYCLOAK_SERVER_URL set to $KEYCLOAK_SERVER_URL"
echo "KEYCLOAK_REALM set to $KEYCLOAK_REALM"

