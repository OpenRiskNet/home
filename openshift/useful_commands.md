# Some useful Openshift commands and tricks

## Delete all resources associated with a running app
Includes buildconfig,deploymentconfig,service,imagestream,route and pod.
where 'appName' is listed in 'Labels' of 'oc describe [resource] [resource name]' output.
```sh
oc delete all -l app=appName
```

## Listing default templates and images streams
```sh
oc get templates -n openshift
oc get imagestreams -n openshift
```

## Access docker registry
```sh
eval $(minishift docker-env)
```

## Managing roles etc.

```sh
oc adm policy add-cluster-role-to-user cluster-admin user1
```
This method grants cluster-admin role to that use, effectively giving them full access.
A safer approach is:

```
oc adm policy add-cluster-role-to-user sudoer user1
```
This adds sudoer role to the user so that they can add `--as system:admin` or similar to their commands.
