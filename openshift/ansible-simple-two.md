# EC2, Ansible core, two OpenShift nodes
Create a two-node OpenShift installation from a central Ansible installer node.

Here we'll be creating a central Ansible server and two servers that will be
provisioned from the Ansible server as an OpenShift master (and application)
node and a single additional application node.

*   We will need three server instances
*   The servers will reside on Amazon's Elastic Compute Cloud (EC2)
*   This guide assumes that you have an account on Amazon AWS and
    therefore does not describe setting up the account
    
Follow the setup instructions from the [Ansible one node](ansible-simple-one.md)
example. This describes the installation of the Ansible node and a joint
master/application node.

Complete the steps described in **Preparing your Amazon EC2 instances** by
following the **Creating the Ansible host** and **Creating the OpenShift host**
sections.

Once done you should repeat the **Creating the OpenShift host** section to
create your third server and give this third server the tag `openshift-one-app`.
The Elastic IP only needs to be used for `openshift-one-master` so this
still needs setting up as described.

>   You can save time here by setting **Number of instances** to `2`
    in the **Configure Instance Details** when crating the OpenShift host.
    You can always add separate tags (maybe `openshift-one-master` and
    `openshift-one-app`) for each of the instances later.

>   Remember to add the **Elastic IP** to the instance you designate as the
    OpenShift master.

For clarity, name the instances once they have started.

# Preparing the Ansible server
This step is essentially the same as that described in the
[Ansible one node](ansible-simple-one.md) document.
Follow the steps up to but not including the
**Create the OpenShift inventory file** section.

>   Remembering to configure `ssh-agent` as described.

### Create the OpenShift inventory file
This file, declared as the `hostfile` in your `ansible.cfg`,
defines the configuration of the OpenShift server that Ansible will setup.

On your Ansible server...

*   Create a a file (`~/osone-inventory.txt`) and replace instances of
    **ip-10-0-0-126.eu-west-1.compute.internal** and
    **ip-10-0-0-236.eu-west-1.compute.internal** in the example below
    with the **Private DNS** address Amazon assigned to _your_ 2nd and 3rd
    (`openshift-one-master` and `openshift-one-app`) servers. 

*   Replace `abc.informaticsmatters.com` with your own DNS name

```
# Create an OSEv3 group that contains the masters and application node groups
[OSEv3:children]
masters
nodes
etcd
nfs

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
# SSH user, this user should allow ssh based auth without requiring a password
ansible_ssh_user=centos
ansible_become=yes
openshift_deployment_type=origin
openshift_release=v3.6
openshift_disable_check=docker_storage,memory_availability,disk_availability

openshift_master_cluster_public_hostname=abc.informaticsmatters.com
openshift_master_default_subdomain=abc.informaticsmatters.com
# Enable htpasswd authentication
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/users.htpasswd'}]
# make sure this htpasswd file exists
openshift_master_htpasswd_file=/home/centos/users.htpasswd

# host group for masters
[masters]
ip-10-0-0-126.eu-west-1.compute.internal

# host group for etcd
[etcd]
ip-10-0-0-126.eu-west-1.compute.internal

# host group for nodes,
[nodes]
ip-10-0-0-126.eu-west-1.compute.internal openshift_node_labels="{'region': 'infra'}" openshift_schedulable=true
ip-10-0-0-236.eu-west-1.compute.internal openshift_node_labels="{'region': 'infra'}"

# NFS hosts
[nfs]
ip-10-0-0-126.eu-west-1.compute.internal
```

We're nearly ready to go...

## Deploy OpenShift
As we've reused filenames, to get you two-node OpenShift cluster running,
you can follow the steps described in the **Deploy OpenShift** section of the
[Ansible one node](ansible-simple-one.md) sister document.

The above orchestration step is likely to take about 15 minutes.

### After installation
You should be able to `ssh` to the master node and use the command-line
OpenShift cluster command (`oc`) to inspect the setup. Obviously the
names returned for you will be different.

    $ oc get nodes
    NAME                                       STATUS    AGE       VERSION
    ip-10-0-0-126.eu-west-1.compute.internal   Ready     3m        v1.6.1+5115d708d7
    ip-10-0-0-236.eu-west-1.compute.internal   Ready     3m        v1.6.1+5115d708d7

And the more comprehensive...

    $ oc get all
    NAME                  DOCKER REPO                                                 TAGS      UPDATED
    is/registry-console   docker-registry.default.svc:5000/default/registry-console   latest    2 minutes ago

    NAME                  REVISION   DESIRED   CURRENT   TRIGGERED BY
    dc/docker-registry    1          1         1         config
    dc/registry-console   1          1         1         config
    dc/router             1          2         2         config

    NAME                    DESIRED   CURRENT   READY     AGE
    rc/docker-registry-1    1         1         1         2m
    rc/registry-console-1   1         1         1         2m
    rc/router-1             2         2         2         3m

    NAME                      HOST/PORT                                             PATH      SERVICES           PORT      TERMINATION   WILDCARD
    routes/docker-registry    docker-registry-default.abc.informaticsmatters.com              docker-registry    <all>     passthrough   None
    routes/registry-console   registry-console-default.abc.informaticsmatters.com             registry-console   <all>     passthrough   None

    NAME                   CLUSTER-IP       EXTERNAL-IP   PORT(S)                   AGE
    svc/docker-registry    172.30.141.31    <none>        5000/TCP                  2m
    svc/kubernetes         172.30.0.1       <none>        443/TCP,53/UDP,53/TCP     6m
    svc/registry-console   172.30.174.60    <none>        9000/TCP                  2m
    svc/router             172.30.111.185   <none>        80/TCP,443/TCP,1936/TCP   3m

    NAME                          READY     STATUS    RESTARTS   AGE
    po/docker-registry-1-cxkr5    1/1       Running   0          2m
    po/registry-console-1-lrb8h   1/1       Running   0          2m
    po/router-1-fm3sq             1/1       Running   0          2m
    po/router-1-hjtwl             1/1       Running   0          2m

You should also be able to open the OpenShift HTTPS console using a DNS
that you attached to your **Elastic IP** instance using the `developer`
user and password you setup earlier, e.g. something like...

    https://abc.informaticsmatters.com:8443
    
>   Remember, at the time of writing, `Chrome` or `Firefox` was more reliable
    than `Safari`.

From here (or using `oc`) you should be able to create projects and applications.

# TODO

1.  Add custom certificates
1.  Configure persistence (glusterfs?)
1.  Configure persistence for docker repository
1.  Add non-infrastructure nodes
1.  Add logging
1.  Add metrics
1.  Define what a HA cluster would look like


