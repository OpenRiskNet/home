BridgeDb service to allow mapping gene and protein identifiers.

## Deploying

*To deploy*:
```
$ ./bridgedb-deploy.sh 
deploymentconfig "bridgedb" created
service "bridgedb" created
route "bridgedb-app" created
route "bridgedb-swagger" created
```

The image tag to be used can be specified with the `IMAGE_TAG` parameter.

The base hostname that is used can be specified with the `ROUTES_BASENAME` parameter that is determined by the 
`$OS_ROUTES_BASENAME` environment variable that is automatically sourced from the file `../setenv.sh`.


*To undeploy*:
```
$ ./bridgedb-undeploy.sh 
deploymentconfig "bridgedb" deleted
route "bridgedb-app" deleted
route "bridgedb-swagger" deleted
service "bridgedb" deleted
```
