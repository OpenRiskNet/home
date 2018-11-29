# Post Certificate Renewal Problems

The following problems have been observed after renewing certificates
(see the [Renew Certificates](../recipes/renew-certificates/README.md) recipe).

## Lost Route (KeyCloak/SSO

Connection to SSO fails as it is found not to be serving the `Route`.

This is essentially caused by a lost **Destination CA Cert** in the `Route`
definition. To resolve the issue you need to re-insert the certificate value
from a copy in the `Service` definition.

1.  Inspect the YAML for the SSO **Service** (`secure-sso`)
1.  You will see a secret for thew metadata annotation
    `service.alpha.openshift.io/serving-cert-secret-name`. Its value is
    probably `sso-x509-https-secret`
1.  Inspect (**Reveal**) the **Secret**'s `tls.crt` value. The missing certificate
    is the 2nd `BEGIN CERTIFICATE` block of the value. Take a copy of
    this certificate block
1.  Navigate to the `sedfure-sso` **Route** and select the `Edit` Action.
1.  Paste the copied certificate block the **Destination CA Certificate**
    text field and then hit `Save`
    
The application and route should now be connected.

---

Tim Dudgeon/Alan Christie  
November 2018
