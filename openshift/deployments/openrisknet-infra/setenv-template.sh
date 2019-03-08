#!/bin/bash

# Here we use the 'dev' site values as an example.
# Once you set the admin user and password that was created
# when the cluster was installed these variable values should deploy
# the dev-site's infrastructure as the 'developer' user.
#
# Modify values to suit your requirements...

# You MUST define these...

export OC_ADMIN=SetMe
export OC_ADMIN_PASSWORD=SetMe
export OC_USER=SetMe
export OC_USER_PASSWORD=SetMe

# You CAN define these...

export OC_MASTER_HOSTNAME=dev.openrisknet.org
export OC_MASTER_URL=https://${OC_MASTER_HOSTNAME}:8443
export OC_ROUTES_BASENAME=${OC_MASTER_HOSTNAME}

export OC_INFRA_VOLUME_TYPE=dynamic
export OC_INFRA_VOLUME_STORAGE_CLASS=glusterfs-storage

export KEYCLOAK_INSECURE_ROUTE=Redirect
export KEYCLOAK_SERVER_URL=https://sso.${OC_ROUTES_BASENAME}/auth
export KEYCLOAK_REALM=openrisknet

export OC_INFRA_HOURLY_BACKUP_COUNT=0
export OC_INFRA_HOURLY_BACKUP_SCHEDULE="7 23 * * *"
export OC_INFRA_DAILY_BACKUP_COUNT=0
export OC_INFRA_DAILY_BACKUP_SCHEDULE="37 3 * * *"
export OC_INFRA_BACKUP_VOLUME_SIZE=10Gi

export OC_INFRA_PROJECT=openrisknet-infra
export OC_INFRA_PROJECT_DISPLAY_NAME="OpenRiskNet Infrastructure"
export OC_INFRA_SA=openrisknet

export OC_POSTGRESQL_SERVICE=db-postgresql
export OC_POSTGRESQL_VOLUME_SIZE=5Gi
