# Certificate Renewal
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

### Running the playbook (production system)
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
     
...you should be able to renew and fetch new certificates with the following
playbook command, normally executed from the `site-prd` directory: -

    $ ansible-playbook -i inventory \
        ~/github/openrisknet/home/openshift/recipes/renew-certificates/site.yml

With this done you should then be able to run the OpenShift-provided certificate
deployment playbook, which for our 3.7 production deployment can be achieved
with this play: -

    $ ansible-playbook -i inventory \
        ~/github/openshift-ansible-release-3.7/playbooks/byo/openshift-cluster/redeploy-certificates.yml

---

Alan Christie  
July 2018

[ansible]: https://docs.ansible.com
[roles]: https://docs.ansible.com/ansible/2.5/user_guide/playbooks_reuse_roles.html
[certbot]: https://certbot.eff.org
