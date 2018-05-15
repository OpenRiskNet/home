# Securing service communication via TLS

For most uses, the normal communication of services with each other inside the cluster does not have to be secured via TLS because the cluster internally can be assumed to be a secure environment. For cases where a higher security standard is required, it may be desireable to enable this. This document outlines what steps should be taken to do this using an Nginx container inside a pod as a TLS terminating reverse proxy.

### Adding a TLS terminating reverse proxy to a pod

Two steps have to be taken to create a working TLS terminating reverse proxy as a sidecar container in a pod to enable secure communication with a service.

First, the TLS certificates have to be generated. These can either be self-signed certificates that clients have to add as well since they are not part of any standard certificate authority chains, or certificates can be bought from certificate authorities which can then be automatically resolved by clients using their list of trusted certificate authorities.

Second, an nginx reverse proxy has to be added to the pod that exposes the standard TLS port 443 and then internally forward traffic to the (unsecured) http port of the service that is being proxied within the same pod.

A step by step guide on how to do both of these steps is availabe [here](https://vorozhko.net/kubernetes-sidecar-pattern-nginx-ssl-proxy-for-nodejs).
