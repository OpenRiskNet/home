# Some useful Openshift commands and tricks

Delete all resources associated with a running app, includes
buildconfig,deploymentconfig,service,imagestream,route and pod,
where 'appName' is listed in 'Labels' of 'oc describe [resource] [resource name]' output.
```sh
oc delete all -l app=appName
```

Listing default templates and images streams
```sh
oc get templates -n openshift
oc get imagestreams -n openshift
```

Access docker registry
```sh
eval $(minishift docker-env)
```
