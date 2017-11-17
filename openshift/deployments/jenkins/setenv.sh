if [ ! -f ../setenv.sh ]; then
  echo "***************** ERROR: setenv.sh in the parent dir is not defined"
  echo "***************** Use setenv-example.sh as a template"
  return
fi

source ../setenv.sh

export OC_ADMIN=admin
export OC_HOST=https://dev.openrisknet.org:8443
export OC_PROJECT=jenkins

echo "OC_PROJECT set to $OC_PROJECT"
echo "OC_MASTER_HOSTNAME set to $OC_MASTER_HOSTNAME" 
echo "OC_ROUTES_BASENAME set to $OC_ROUTES_BASENAME"
