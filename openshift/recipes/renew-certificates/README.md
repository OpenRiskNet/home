# Certificate Renewal
An ansible playbook and roles that can be used to renew
Let's Encrypt/[Certbot]-like SSL certificates in an OpenShift cluster.

The steps involve...

-   Renewing certificates using the first master node
-   Fetching them back to the bastion ready for deployment
-   Running the OpenShift certificate redeployment playbook

## Running the playbook (production system)
With this repository checked out on the bastion to `~/github/openrisknet/home`
(which would be normal if you've installed an OpenShift system using
accompanying recipes).
 
You should be able to renew and collect new certificates with the following
command, normally executed from the `site-prd` directory: -

    $ ansible-playbook -i inventory \
        ~/github/openrisknet/home/openshift/recipes/renew-certificates/site.yml

This will place the certificates in the directory indicated by the inventory.

With this done you should then be able to run the OpenShift certificate
deployment playbook, which for our 3.7 production deployment can be achieved
with this play: -

    $ ansible-playbook -i inventory \
        ~/github/openshift-ansible-release-3.7/playbooks/byo/openshift-cluster/redeploy-certificates.yml

---

Alan Christie  
July 2018

[certbot]: https://certbot.eff.org
