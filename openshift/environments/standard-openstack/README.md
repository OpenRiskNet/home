# Standard deployment on Openstack

WARNING - this is work in progress. Curretly is sets up a standard availability Orign v3.7.2 cluster on an
OpenStack cloud.

This configuration is used to create the current OpenRiskNet [production environment](https://prod.orpenrisknet.org). 

This provides moderate scaleability but there is no redundancy so there are several single points of failure.
Shared filesystems for persistent volumes are provided by NFS, Cinder and GlusterFS.

Not suitable for situations where high availability is required.

Not suitable for large clusters as there is insufficient redundancy of services.

The deployment consists of these nodes:

**Bastion node** e.g. bastion

* SSH to this node to create and manage the cluster
* Avoids cluttering the master node with unnecessary modules and content
* Does NOT form part of the OpenShift cluster
* Optionally can provide DNS to the cluster
* Needs a public IP address

**Master node** e.g. orn-master

* Single master node also providing etcd
* Provides console and API
* Needs a public IP address and hostname

**Infrastructure node** e.g. orn-infra

* Node labelled as `infra` region where router and docker repository pods run
* Provides NFS server to the cluster
* Needs a public IP address and hostname

**Worker nodes** e.g. orn-node-001, orn-node-002 ...

* Standard nodes where normal pods run
* Does not need to be publicly accessible
* Specify as many of these as you need. This example uses 4.

**GlusterFS nodes** e.g. orn-gluster-storage-001, orn-gluster-storage-002, orn-gluster-storage-003

* Storage nodes running pods related to GlusterFS storage
* Does not need to be publicly accessible
* Needs to be at least 3 nodes
* This implementaion provides 3-way replicated, 3-way distributed storage
* GlusterFS is optional and may not be suited to small clusters

## Create OpenStack network

Create network, subnet, router and security group.

TODO - describe details

IMPORTANT - open up the security group so that all TCP and UDP traffic is allowed within the subnet.
TODO - potentially restrict this to only the necessary protocols and ports to enhance security

## Prepare Bastion node

Create a new Centos7 images for your bastion node and prepare it like this (as root or using sudo):

```
yum -y update
yum -y install wget git net-tools bind-utils bash-completion python-devel python-passlib java-1.8.0-openjdk-headless httpd-tools

yum -y install docker
systemctl enable docker
systemctl start docker

yum -y install https://rdoproject.org/repos/rdo-release.rpm
yum -y install python-openstackclient 
yum -y install python-heatclient

sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/rdo-release.repo
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/rdo-testing.repo
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/rdo-qemu-ev.repo

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo

yum -y install --enablerepo=epel ansible pyOpenSSL
```

### DNS setup

OpenStack has an optional DNS feature that provides hostname resolution within the subnet.
The SSC Uppmax region on which the production environment is running has this feature enabled 
so we make use of it. It means that the names of the servers that are created can be resolved
automatically without the need for spcifically handle DNS name resolution.

If automatic DNS name resolution is not available then you must provide one or more nameservers that
can provide this service. One way to do this is to have a dedicated `dns` node running on the subnet 
that runs dnsmasq and to add the names of the servers to this.

Whatever the solution for DNS, the name(s) of the nameservers should be defined in the OpenStack subnet 
definition. If using the optional DNS service then the nameservers (something like 10.0.0.2, 10.0.0.3 and 10.0.0.4) 
will probably already be set as the name servers for the subnet. If you define your own DNS servers then
you should change the defintion of the subnet to point to these nameservers. 

With those settings defined for the subnet all servers created on that subnet will automatically use
those nameservers as default (note - installing OpenShift will change the DNS configuration on each node).

#### Setting up a dedicated nameserver

As mentioned in the previous section, you might need to provide a DNS server on the subnet that can 
resolve local and public hostnames.

For convenience we do this on the bastion node, but a dedicated node could aslo be used.

On this node install `dnsmasq` which will be our DNS server.
```
sudo yum install -y dnsmasq
```

Edit the `/etc/dnsmasq.conf` and add an entry like this `server=8.8.8.8` to specify a public DNS server to
delegate to. 

In the OpenStack configuration edit the dnsservers for the subnet and specify the IP number of your DNS node.

Reboot your node.


## Create nodes

We aim to automate the creation of nodes using Terraform and Ansible.
The [KubeNow project](https://github.com/kubenow/KubeNow) aims to acheive this.
However, we have hit a significant problem that results in servers that are created not functioning correctly.
This appears to be some combination of fagilities in the OpenStack environment and the OpenShift Ansible installer.
We do not yet fully understand these issues, but the result is that a proportion of nodes (up to ~50% depending
on the OpenStack environment) fail to work correctly when the Ansilbe installer is run. 
Look at this [GitHub issue](https://github.com/openshift/openshift-ansible/issues/7967) for some details.

As a result it is impossible to automatically create a cluster so instead we currently use a semi-manual
incremental approach.

We use the openstack python client to create the nodes, but the same can be done through the web console.

### Define environment

Define the environment variables that define the features of your cluster:
```
export PREFIX=orn
export DOMAIN=openstacklocal
export SECGRP=orndev-secgroup
export KEY=orndev-keypair-ab06c8b9e153710c61eb5148
export NET=orndev-network
export IMAGE=centos-1802-os-base-01-A
```

Create a `user-data.sh` file that is used by the cloud init process. This sets the hostname of the servers to
be the correct. We need the name to be the same as the hostname (see below on the OpenStack cloud provider)
but if you set the server name in OpenStack to `xxx.openstacklocal` then the default hostname that is defined
in the server is `xxx.openstacklocal.openstacklocal` so we must change this once the server is running.

```
#!/bin/bash
hostnamectl set-hostname $(hostname -s).openstacklocal
```


### Node creation

Edit this creation script to reflect the nodes in your cluster e.g. change the number of nodes or the number of GlsuterFS volumes.
```
#!/bin/bash

source setenv.sh

echo "Creating master"
openstack server create --wait --image $IMAGE --flavor ssc.large --security-group $SECGRP --key-name $KEY --network $NET --user-data user-data.sh $PREFIX-master.$DOMAIN

echo "Creating infra"
openstack server create --wait --image $IMAGE --flavor ssc.xlarge --security-group $SECGRP --key-name $KEY --network $NET --user-data user-data.sh $PREFIX-infra.$DOMAIN

echo "Creating node 1"
openstack server create --wait --image $IMAGE --flavor ssc.xlarge --security-group $SECGRP --key-name $KEY --network $NET --user-data user-data.sh $PREFIX-node-001.$DOMAIN

echo "Creating node 2"
openstack server create --wait --image $IMAGE --flavor ssc.xlarge --security-group $SECGRP --key-name $KEY --network $NET --user-data user-data.sh $PREFIX-node-002.$DOMAIN

echo "Creating node 3"
openstack server create --wait --image $IMAGE --flavor ssc.xlarge --security-group $SECGRP --key-name $KEY --network $NET --user-data user-data.sh $PREFIX-node-003.$DOMAIN

echo "Creating node 4"
openstack server create --wait --image $IMAGE --flavor ssc.xlarge --security-group $SECGRP --key-name $KEY --network $NET --user-data user-data.sh $PREFIX-node-004.$DOMAIN

echo "Creating gluster 1"
openstack server create --wait --image $IMAGE --flavor ssc.large --security-group $SECGRP --key-name $KEY --network $NET --user-data user-data.sh $PREFIX-gluster-storage-001.$DOMAIN

echo "Creating gluster 2"
openstack server create --wait --image $IMAGE --flavor ssc.large --security-group $SECGRP --key-name $KEY --network $NET --user-data user-data.sh $PREFIX-gluster-storage-002.$DOMAIN

echo "Creating gluster 3"
openstack server create --wait --image $IMAGE --flavor ssc.large --security-group $SECGRP --key-name $KEY --network $NET --user-data user-data.sh $PREFIX-gluster-storage-003.$DOMAIN

openstack volume create --size 100 $PREFIX-gluster-storage-001-B
openstack volume create --size 100 $PREFIX-gluster-storage-002-B
openstack volume create --size 100 $PREFIX-gluster-storage-003-B

openstack volume create --size 100 $PREFIX-gluster-storage-001-C
openstack volume create --size 100 $PREFIX-gluster-storage-002-C
openstack volume create --size 100 $PREFIX-gluster-storage-003-C

openstack volume create --size 100 $PREFIX-gluster-storage-001-D
openstack volume create --size 100 $PREFIX-gluster-storage-002-D
openstack volume create --size 100 $PREFIX-gluster-storage-003-D

openstack server add volume --device /dev/vdb $PREFIX-gluster-storage-001.$DOMAIN $PREFIX-gluster-storage-001-B
openstack server add volume --device /dev/vdb $PREFIX-gluster-storage-002.$DOMAIN $PREFIX-gluster-storage-002-B
openstack server add volume --device /dev/vdb $PREFIX-gluster-storage-003.$DOMAIN $PREFIX-gluster-storage-003-B

openstack server add volume --device /dev/vdc $PREFIX-gluster-storage-001.$DOMAIN $PREFIX-gluster-storage-001-C
openstack server add volume --device /dev/vdc $PREFIX-gluster-storage-002.$DOMAIN $PREFIX-gluster-storage-002-C
openstack server add volume --device /dev/vdc $PREFIX-gluster-storage-003.$DOMAIN $PREFIX-gluster-storage-003-C

openstack server add volume --device /dev/vdd $PREFIX-gluster-storage-001.$DOMAIN $PREFIX-gluster-storage-001-D
openstack server add volume --device /dev/vdd $PREFIX-gluster-storage-002.$DOMAIN $PREFIX-gluster-storage-002-D
openstack server add volume --device /dev/vdd $PREFIX-gluster-storage-003.$DOMAIN $PREFIX-gluster-storage-003-D

```

Run the script to create the nodes.
Note, that at this stage you do not need to create the GlusterFS nodes - that can be done later.

Check that you can SSH to the servers using the SSH key you specified.
Sometimes servers fail to start correctly and you cannot connnect. If so then delete that server and re-create it.

This script can be handy in checking the connections. Adjust the details to reflect your cluster. 
```
#!/bin/bash

set -x

source setenv.sh

CMD="hostname"
#CMD="ls /etc/cni/net.d"

echo master && time ssh orn-master.$DOMAIN ${1:-hostname}
echo infra && time ssh orn-infra.$DOMAIN ${1:-hostname}
echo node-001 && time ssh orn-node-001.$DOMAIN ${1:-hostname}
echo node-002 && time ssh orn-node-002.$DOMAIN ${1:-hostname}
echo node-003 && time ssh orn-node-003.$DOMAIN ${1:-hostname}
echo node-004 && time ssh orn-node-004.$DOMAIN ${1:-hostname}
echo gluster-001 && time ssh orn-gluster-storage-001.$DOMAIN ${1:-hostname}
echo gluster-002 && time ssh orn-gluster-storage-002.$DOMAIN ${1:-hostname}
echo gluster-003 && time ssh orn-gluster-storage-003.$DOMAIN ${1:-hostname}
```

Once complete, assign public IP addresses to the `master` and `infra` node using the web console. 
The `master` node needs a DNS A record. We'll assume `prod.openrisknet.org`.
The `infra-1` node needs a wildcard DNS A record. We'll assume `*.prod.openrisknet.org`.

If you are providing your own DNS server then edit the `/etc/hosts` file and enter the IP addresses and local
hostnames of all these nodes  so that they can be resolved (dnsmasq uses the /etc/hosts file as part of its
name resolution process). Your file will like something like this:

```
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.0.12 orn-master.openstacklocal orn-master
192.168.0.11 orn-infra.openstacklocal orn-infra
192.168.0.14 orn-node-001.openstacklocal orn-node-001
...
```

Restart dnsmasq to pick up the changes:

```
sudo systemctl restart dnsmasq
```

On the bastion node verify that you can resolve the local hostnames e.g.:
```
$ host orn-master.openstacklocal
```

SSH to the other nodes and verify that you can also resolve the other nodes. Each node MUST be able
to resolve the hostname of the other nodes in the cluster. 
Also the value returned by the `hostname` command must be exactly the same as the name of the instance in the OpenStack
Horizon web console.
Until this all works do not try to install OpenShift.


## Master node certificates

These certificates handle the web console and the REST API.
We use Let's Encrypt as their certificates are trusted and free.
Services on the master do not run on port 80 so certbot can be used in standalone mode.

SSH to the master and install certbot and zip:

```
$ sudo yum -y --enablerepo=epel install certbot zip
```

Generate certificate:

```
$ sudo certbot certonly --standalone -n -m your@email.address --agree-tos -d master.openrisknet.org
```

Replace your email address and domain accordingly.

Zip up the generated certificates and copy them to the bastion node and expand the zip file. 
You will need them when you deploy OpenShift.

## Deploying OpenShift using the Ansible installer

### Inventory file

A sample inventory file is [here](inventory).
Here we higlight key sections.

#### Node definition

Note the defintion of the different sections.
Most of this will not need changing if you need to re-create the servers, but note that the defintions in the `glusterfs`
section include the IP addresses which will change if you need to re-create these servers.

The `new_nodes` section is empty. It is used when you add additional nodes to the cluster.

```
[OSEv3:children]
masters
nodes
etcd
nfs
glusterfs
new_nodes

[masters]
orn-master.openstacklocal

[etcd]
orn-master.openstacklocal

[nfs]
orn-infra.openstacklocal

[glusterfs]
orn-gluster-storage-001.openstacklocal glusterfs_ip=10.0.0.31 glusterfs_devices='[ "/dev/vdb", "/dev/vdc", "/dev/vdd" ]'
orn-gluster-storage-002.openstacklocal glusterfs_ip=10.0.0.24 glusterfs_devices='[ "/dev/vdb", "/dev/vdc", "/dev/vdd" ]'
orn-gluster-storage-005.openstacklocal glusterfs_ip=10.0.0.39 glusterfs_devices='[ "/dev/vdb", "/dev/vdc", "/dev/vdd" ]'

[nodes]
orn-master.openstacklocal   openshift_hostname=orn-master.openstacklocal
orn-infra.openstacklocal    openshift_hostname=orn-infra.openstacklocal openshift_node_labels="{'region': 'infra', 'zone': 'default'}"
orn-node-001.openstacklocal openshift_hostname=orn-node-001.openstacklocal openshift_node_labels="{'region': 'primary', 'zone': 'default'}"
orn-node-002.openstacklocal openshift_hostname=orn-node-002.openstacklocal openshift_node_labels="{'region': 'primary', 'zone': 'default'}"
orn-node-003.openstacklocal openshift_hostname=orn-node-003.openstacklocal openshift_node_labels="{'region': 'primary', 'zone': 'default'}"
orn-node-004.openstacklocal openshift_hostname=orn-node-004.openstacklocal openshift_node_labels="{'region': 'primary', 'zone': 'default'}"
orn-gluster-storage-001.openstacklocal storage=True openshift_hostname=orn-gluster-storage-001.openstacklocal
orn-gluster-storage-002.openstacklocal storage=True openshift_hostname=orn-gluster-storage-002.openstacklocal
orn-gluster-storage-005.openstacklocal storage=True openshift_hostname=orn-gluster-storage-005.openstacklocal

[new_nodes]
```

#### OpenShift version
The version to deploy is largely defined by this section. Exactly what to specify changes between versions and is not well documented
by OpenShift. You make need to experiment and ask to get the details right. 
```
openshift_deployment_type=origin
openshift_release=v3.7.2
openshift_image_tag=v3.7.2
openshift_pkg_version=-3.7.2
```
Also note that despite specifying to install a specific version if OpenShift other components such as metrics and logging do not
use that version by default and you must specify what versions of those to install in the relevant sections.

#### OpenStack cloud provider

This section defines the OpenStack cloud provider configuration. It uses environment variables that must be initialised by
running the `keystone.rc` file for your environment. Other cloud providers such as AWS should also work but have not been tested
at this stage.

```
openshift_cloudprovider_kind = openstack
openshift_cloudprovider_openstack_auth_url = "{{ lookup('env','OS_AUTH_URL') }}"
openshift_cloudprovider_openstack_username = "{{ lookup('env','OS_USERNAME') }}"
openshift_cloudprovider_openstack_password = "{{ lookup('env','OS_PASSWORD') }}"
openshift_cloudprovider_openstack_region = "{{ lookup('env', 'OS_REGION_NAME') }}"
openshift_cloudprovider_openstack_domain_name = "{{ lookup('env', 'OS_USER_DOMAIN_NAME') }}"
openshift_cloudprovider_openstack_tenant_id = "{{ lookup('env','OS_PROJECT_ID') }}"
``` 

Note that for the cloud provider functionality to work the hostname of the machine (what is returned by the `hostname` commannd on that machine)
must be EXACTLY the same as the instance name (e.g. what shows up in the Horizon web console or is returned by `openstack server list`.
Also, that name must be specified as the `openshift_hostname` host property in the nodes sections of the inventory file (see above).

#### Authentication and Certificates

Theese sections define the authentication mechanisms and how to specify the certicate for the master node that you genrated earlier.
Adjust these according to your needs. 

```
# Enable htpasswd authentication
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/users.htpasswd'},{"name": "github", "challenge": false, "login": true, "kind": "GitHubIdentityProvider", "clientID": "8081ebdef265224f3805", "clientSecret": "4c45f42150b1a3e7a734b5ac4bba338b0b4d6005", "teams": ["OpenRiskNet/developers"]}]
# make sure this htpasswd file exists
openshift_master_htpasswd_file=/home/centos/users.htpasswd
```

```
openshift_master_named_certificates=[{"certfile": "/home/centos/site-prd/certs/fullchain.pem", "keyfile": "/home/centos/site-prd/certs/privkey.pem"}]
openshift_master_overwrite_named_certificates=true
```


#### Metrics, Logging, Prometheus
These sections are defined, but in the inventory file they are set not be be installed (e.g. `openshift_metrics_install_metrics=false).
You can install these as part of the standard install by changing those values to `true` but this results in more things that can go wrong
and a slower installation process. We prefer to manually deploy these once we have a running cluster. They can be independently installed 
and uninstalled.


### Clone the openshift/openshift-ansible repo

Clone the repository and switch to the `release-3.7` branch.
We assume you clone it into your home directory.
```
$ git clone --branch release-3.7 https://github.com/openshift/openshift-ansible
```

### Run the installer

#### On an environment where servers do not fail.

If you are lucky enough to be working on an environment where everything just works then you can just run the installer and deploy everything 
in one go.


```
ansible-playbook -i inventory ~/openshift-ansible/playbooks/byo/config.yml
```

If it fails or you want to uninstall do this:

```
ansible-playbook -i inventory-file openshift-ansible/playbooks/adhoc/uninstall.yml
```

#### On an environment where OpenShift fails to deploy to some servers

We find this happens on most environmenets, but to a differing extent.
In the worst case ~50% of the nodes fail. On others the rate is much lower.
Deploying an entire multi-node cluster in one go can be almost impossible in these
circumstances so we instead build it up piece by piece.

The usual symptom of the nodes failing is that the file `/etc/cni/net.d/80-openshift-network.conf` does not get created.
Instead that directory is created but is empty. This is a symptom of the problem, not the cause. See
[GitHub issue](https://github.com/openshift/openshift-ansible/issues/7967) for details.

When this happens that node will NEVER work, even if you try installing again. In contrast, if the installation succeeds
once (and the file gets created) you can uninstall and re-install continually. Hence the only solution is to delete the node
and replace it with a new one, and continue with this process until you are successful.

To delete the node use the web console or the python client.

To re-create the node use the appropriate part of the `create.sh` script (remembering to set up the environment variables first).

The strategy that worked best for us (though others would also work) is:

1. Create the master, infra and worker nodes (not the gluster servers at this stage).
2. Modify the inventory to only deploy to the master and infra. This should give a minimal working cluster.
3. If the installation failed run the `uninstall.yml` playbook, replace the servers(s) that failed and try step 2 again. Repeat until successful.
4. Add the worker nodes (e.g. orn-node-001 ...) to the `new_nodes` section of the inventory
5. Run the `playbooks/byo/openshift-node/scaleup.yml` playbook to scale the cluster up.
6. For the new nodes that succeeded move them from the new_nodes section to the the nodes section of the inventory.
7. For the new nodes that failed delete the server(s) and replace with new ones. 
8. Repeat from step 5 until all nodes are working and present in the nodes section.
9. Repeat steps 4-8 to add the glusterfs nodes. At this stage just add them to the `nodes` section, not the `glusterfs` section.
10. At this stage you should have all your nodes working. Now run the `uninstall.yml` playbook!
11. Modify the inventory file to add the gluster nodes to the `glusterfs` section. Remember to provide the correct IP addresses. At this stage add the volumes that will be used for storage to the gluster nodes if you have not already done so.
12. Finally run the `playbooks/byo/config.yml` playbook to deploy your cluster. At this stage all nodes are proven to work so this should now be successful.
   
### Post install checks
To run some checks SSH to the master and run this:

```
sudo oc adm diagnostics
```

NOTE: some of the errors and warnings you see will be false alarms. But if there are real problems you
should see them.


### Install Metrics and Logging.

Set the install parameter in the inventory file to `true` for these and run these playbooks:

```
ansible-playbook -i inventory ~/openshift-ansible/playbooks/byo/openshift-cluster/openshift-metrics.yml
```

```
ansible-playbook -i inventory ~/openshift-ansible/playbooks/byo/openshift-cluster/openshift-logging.yml
```

### Prometheus

We are still establishing the best approach to installing Prometheus. 


