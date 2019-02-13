# Certificate Renewal

>   Caution: Depending on your OpenShift version the playbooks may be limited to
    [Ansible] v2.5 or v2.4.

>   From March 13th 2019 TLS-SNI-01 validation will have reached
    its end-of-life for support. If you have problems renewing
    certificates you probably just need to make sure that you're running
    an up-to-date certbot binary. If `certbot --version` reports `0.28` or
    higher you should be OK. For further details refer to
    the [tls-sni-01] article. 
    
An [ansible] playbook and roles for a CentOS deployment that can be used to renew
Let's Encrypt/[Certbot]-like SSL certificates in an OpenShift cluster.
The playbook contains two [roles] that involve...

-   **Renewing** certificates using the first master node. The renewal role
    executes tasks on the first master in your inventory file. It makes sure
    that `certbot` is installed on the master and then uses it to make a
    renewal request using the `certonly` command. A `standalone` webserver
    is used to obtain the actual certificates. If your certificates are not
    about to expire (usually if they're not within 30 days of expiry) the
    renewal does not take place. Collected certificates are normally found
    in the `/etc/letsencrypt/live` directory on the master, under a directory
    that matches the `openshift_master_cluster_public_hostname` variable
    in your inventory (e.g. `prod.openrisknet.org`).
-   **Fetching** them back to the bastion ready for deployment. Once the
    renewal role has completed the certificate files (`cert.pem`,
    `chain.pem`, `fullchain.pem` and `privkey.pem`) are fetched from the
    first master node to the bastion and placed in the directory
    defined by the OpenShift `openshift_master_named_certificates` variable in
    your inventory (typically `~/site-prd/certs`). Files that have not
    changed are not copied, which may happen with the `chain.pem` file for
    example. Rest assured that if your local files have not changed then
    they probably didn't need to.
    
When certificate renewal has taken place you need to deploy them using
the OpenShift-provided playbook, which will pickup the new certificate
files and deploy them to the master.

An execution example follows.

## Running the playbook (production system)
You need to make sure that you have ssh access to the master node form the
bastion, an expectation of the renewal Ansible playbook.

With this repository checked out on the bastion to `~/github/openrisknet/home`
(which would be normal if you've installed an OpenShift system using
accompanying recipes)...

>   Renewal requires a registration email. The email address used is
    a variable in the `renew-certificates` role. If you need to provide your
    own email address or are unsure which one is being used you can set
    your own value on the command line by adding
    `--extra-vars "certbot_email=blob@xyz.com"`.
    
>   As this renewal process requires the port used by the Master's API
    service the API service is stopped by the playbook during the
    certificate renewal, which typically lasts for about a minute or so,
    depending on network performance. 
     
...you should be able to renew and fetch new certificates with the following
playbook command, normally executed from the `site-prd` directory.

>   If you have used the *orchestrator* to deploy the cluster you should execute
    the playbook from the appropriate *inventories* directory.
    For the **Development** site this might be
    `abc/orchestrator/openshift/inventories/hpc2n-37`.
    
Once you have the correct inventory file run the playbook with the following
command: -

    $ ansible-playbook -i inventory \
        ~/github/openrisknet/home/openshift/recipes/renew-certificates/site.yml

With this done you should then be able to run the OpenShift-provided certificate
deployment playbook, which for our 3.7 production deployment can be achieved
with this play: -

    $ ansible-playbook -i inventory \
        ~/github/openshift-ansible-release-3.7/playbooks/byo/openshift-cluster/redeploy-certificates.yml

In OpenShift 3.9 the certificate redeployment playbook has moved. In 3.9 you'd run: -

    $ ansible-playbook -i inventory \
        ~/github/openshift-ansible-release-3.9/playbooks/redeploy-certificates.yml

## Renewing certificates for a specific node
You can renew certificates for a specific node by placing the node hostname
in a the `[new_nodes]` section of the inventory file. You should make sure
the hostname is copied here, not moved. For example, to redeploy to
`orn-node-004.openstacklocal` the `[new_nodes]` section will look like this:

    [new_nodes]
    orn-node-004.openstacklocal

Then run the following playbook...

    $ ansible-playbook -v -i inventory \
        ~/github/openshift-ansible-release-3.7/playbooks/certificate_expiry/easy-mode.yaml
        
Once done remove the chosen host from the `[new_nodes]` section.

## Generating a certificate expiry report
The following playbook produces a report file in `/tmp/cert-expiry-report.json`: -

    $ ansible-playbook -v -i inventory \
        ~/github/openshift-ansible-release-3.7/playbooks/certificate_expiry/easy-mode.yaml 

## Post deploy issues

1.  It is possible that the KeyCloak/SSO Route (or any other *Redirected* Route)
    may have been disrupted by the certificate deployment. If KeyCloak/SSO
    is deployed check the route and, if the application is not responding,
    review the solution suggested in the
    [knowledge base](../../knowledge-base/post-certificate-renewal-problems.md) article.
 
---

Alan Christie  
January 2019

[ansible]: https://docs.ansible.com
[tls-sni-01]: https://community.letsencrypt.org/t/how-to-stop-using-tls-sni-01-with-certbot/83210)
[roles]: https://docs.ansible.com/ansible/2.5/user_guide/playbooks_reuse_roles.html
[certbot]: https://certbot.eff.org
