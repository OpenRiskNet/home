# Some useful Openshift commands and tricks

## Delete all resources associated with a running app
Includes buildconfig,deploymentconfig,service,imagestream,route and pod.
where 'appName' is listed in 'Labels' of 'oc describe [resource] [resource name]' output.
```sh
oc delete all -l app=appName
```

That may not remove _everything_. You might also need to delete
secrets, persistent volume claims and persistent volumes.

```
oc get secrets
oc delete secrets/<secret>
oc get pvc
oc delete pvc/<pvc>
oc get pv --as system:admin
oc delete pv/<pv> -- as system:admin
```

For these latter commands you will need privileges which you can grant
a user from the master node admin account (see **Managing Roles** below).

```
ssh -i .ssh/<keyfile>.pem centos@<addr>
oc login -u system:admin
oc adm policy add-cluster-role-to-user sudoer <user>
```

## Getting information on a pod
This displays significant information about a pod including and
`Events`.
```sh
oc describe pods <name>
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


```
oc adm policy add-scc-to-group anyuid system:authenticated
```
This allows cotnainers to be run as a image defined user ID (inlcuding root) by any authenticated user. 
