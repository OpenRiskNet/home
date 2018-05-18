JGU WEKA REST Service. A RESTful API Webservice to WEKA Machine Learning Algorithms. 

## Deploying

*To deploy*:
```
$ ./deploy.sh 
imagestream "mongodb" created
imagestream "jguweka" created
deploymentconfig "mongodb" created
deploymentconfig "jguweka" created
service "mongodb" created
service "jguweka" created
route "jguweka" created
```

The image tag to be used can be specified with the `IMAGE_TAG` parameter in os-jguweka-template.yaml.

The base hostname that is used can be specified with the `ROUTES_BASENAME` parameter that is determined by the 
`$OS_ROUTES_BASENAME` environment variable that is automatically sourced from the file `setenv.sh`.


*To undeploy*:
```
$ ./undeploy.sh 
imagestream "jguweka" deleted
imagestream "mongodb" deleted
deploymentconfig "jguweka" deleted
deploymentconfig "mongodb" deleted
route "jguweka" deleted
service "jguweka" deleted
service "mongodb" deleted
```
