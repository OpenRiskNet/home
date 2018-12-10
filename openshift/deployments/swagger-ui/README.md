# Swagger UI deployment

Swagger UI is a Javascript application that lets you explore REST APIs described with Swagger (OpenAPI).
You can point Swagger UI to your Swagger descriptor and then explore and test its options.

This deployment is at the experimental stage. It is based on the https://github.com/sabre1041/openshift-api-swagger
project which uses Swagger UI to explore the OpenShift and Kubernetes REST APIs. We expect to extend this to allow
to explore the OpenRiskNet APIs by hooking Swagger UI into the APIs that have been discovered by the
[OpenRiskNet Registry](http://orn-registry-openrisknet-registry.prod.openrisknet.org/).

Instructions for deploying this Swagger UI application to an OpenRiskNet VRE are described in the GitHub repository 
for the deployment to the OpenRiskNet refefrence site: https://github.com/OpenRiskNet/openshift-api-swagger/blob/master/README-OPENRISKNET.md
