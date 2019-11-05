# Deploying a Custom Master Host Certificate
Armed with a single domain certificate you can deploy this to the master
via the inventory or update a pre-existing certificate.

>   For reference consult the OpenShift [documentation] on the topic at
    
## Via the inventory
Usually, as a pre-OpenShift deployment, you'd prepare the certificates
and adjust your OpenShift inventory.

You will need: -

-   A `certfile` that is the concatenation of the primary certificate
    _and_ any additional certificate (i.e. the CA bundle). This file is
    essentially all the certificate in one (with certificate _in order_
    starting with the primary). See the **Configuring a Certificate Chain**
    in the [documentation].
-   A  `keyfile` that's the private key for the certificates
-   The `names` of the cluster's Master hostname (i.e. `prod.openrisknet.org`)

With the above files in the `/home/centos` directory add the following
to the (yaml) inventory file: -

```yaml
openshift_master_named_certificates: [
    { 'certfile': "/home/centos/okd-orchestrator/cert.crt",
      'keyfile': "/home/centos/okd-orchestrator/private.key",
      'names': ["prod.openrisknet.org"] }
]
openshift_master_overwrite_named_certificates: true
```

Then just deploy OpenShift.

## Retrofitting

The [documentation] has information relating to
**Retrofit Custom Certificates into a Cluster**. So, if you've already
deployed the cluster you could use these instructions to update the
certificate.

---

[documentation]: ttps://docs.openshift.com/container-platform/3.11/install_config/certificate_customization.html
