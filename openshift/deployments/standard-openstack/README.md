# Standard deployment on Openstack

WARNING - this is work in progress. 

Provides moderate scaleability but there is no redundancy so there are several single points of failure.
Shared filesystems for persistent volumes are provided by NFS.

Not suitable for situations where high availability is required.

Not suitable for large clusters as there is insufficient redundancy of services and NFS does not scale sufficiently.

The deployment consists of these nodes:

**Bastion node** e.g. bastion

* SSH to this node to create and manage the cluster
* Avoids cluttering the master node with unnecessary modules and content
* Does NOT form part of the OpenShift cluster
* Provides DNS to the cluster (this is specific to OpenStack)
* Needs public IP address

**Master node** e.g. master-1

* Single master node also providing etcd
* Provides console and API
* Needs public IP address and hostname

**Infrastructure node** e.g. infra-1

* Node labelled as `infra` region where router and docker repository pods run
* Provides NFS server to the cluster
* Needs public IP address and hostname

**Worker nodes** e.g. infra-1, infra-2

* Standard nodes where normal pods run
* Does not need to be publicly accessible
* Specify as many of these as you need. This example uses 2.


## Create OpenStack network

Create network, subnet, router and security group.
Initially set up the subnet so that it has a public nameserver such as 8.8.8.8

TODO - describe details

IMPORTANT - open up the security group so that all TCP and UDP traffic is allowed within the subnet.
TODO - potentially resrict this to only the necessary protocols and ports to enhance security

### DNS setup

OpenStack does not provide hostname resolution within the subnet which makes this more difficult than
environments like AWS where this happens automatically.

To work around this we provide a DNS server on the subnet that can resolve local and public hostnames.
For convenience we do this on the bastion node, but a dedicated node could be used.

Create the bastion node (base from centos7). TODO - describe details.

On this bastion node install `dnsmasq` which will be our DNS server. TODO - describe details.

Edit the `/etc/dnsmasq.conf` and add an entry like this `server=8.8.8.8` to specify a public DNS server to
delegate to. 

In the OpenStack configuration edit the dnsservers for the subnet and specify the IP number of your bastion node.

Reboot your bastion node.


## Create nodes

Create master-1, infra-1, worker-1, worker-2 nodes
TODO - describe details

master-1 and infra-1 need public IP addresses.

master-1 needs a DNS A record. We'll assume master.openrisknet.org.

infra-1 needs a wildcard DNS A record. We'll assume *.apps.openrisknet.org.

On the bastion node edit the `/etc/hosts` file and enter the IP addresses and local hostnames of all these nodes 
so that they can be resolved (dnsmasq uses the /etc/hosts file as part of its name resolution process). Your file
will like something like this:

```
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.0.12 master-1 master-1.openstacklocal
192.168.0.11 infra-1  infra-1.openstacklocal
192.168.0.14 worker-1 worker-1.openstacklocal
192.168.0.18 worker-2 worker-2.openstacklocal
```

Restart dnsmasq to pick up the changes:

```
sudo systemctl restart dnsmasq
```

On the bastion node verify that you can resolve the local hostnames:

```
host master-1
```

SSH to the other nodes and verify that you can also resolve the other nodes. Each node MUST be able
to resolve the hostname of the other nodes in the cluster. Until this works do not try to install OpenShift.


## Master node certificates

These certificates handle the web console and the REST API.
We use Let's Encrypt as their certificates are trusted and free.
Services on the master do not run on port 80 so certbot can be used in standalone mode.

SSH to the master and install certbot and zip:

```
sudo yum -y --enablerepo=epel install certbot zip
```

Generate certificate:

```
sudo certbot certonly --standalone -n -m your@email.address --agree-tos -d master.openrisknet.org
```

Replace your email address and domain accordingly.

Zip up the generated certificates and copy them to the bastion node and expand the zip file.

## Inventory file

```
[OSEv3:children]
masters
nodes
etcd
nfs

[OSEv3:vars]
ansible_ssh_user=centos
ansible_become=yes

openshift_deployment_type=origin
openshift_release=v3.6

openshift_disable_check=disk_availability,docker_storage,memory_availability
openshift_clock_enabled=true

# Enable htpasswd authentication
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/users.htpasswd'}]
# make sure this htpasswd file exists
openshift_master_htpasswd_file=/home/centos/users.htpasswd

openshift_master_cluster_public_hostname=master.openrisknet.org
openshift_master_default_subdomain=apps.openrisknet.org

openshift_master_named_certificates=[{"certfile": "/home/centos/certs/master.openrisknet.org/fullchain.pem", "keyfile": "/home/centos/certs/master.openrisknet.org/privkey.pem"}]
openshift_master_overwrite_named_certificates=true

openshift_hosted_metrics_deployer_version=v3.6.0
openshift_hosted_metrics_deploy=true
openshift_hosted_metrics_storage_kind=nfs
openshift_hosted_metrics_storage_access_modes=['ReadWriteOnce']
openshift_hosted_metrics_storage_nfs_directory=/exports
openshift_hosted_metrics_storage_nfs_options='*(rw,root_squash)'
openshift_hosted_metrics_storage_volume_name=metrics
openshift_hosted_metrics_storage_volume_size=10Gi
openshift_hosted_metrics_storage_labels={'storage': 'metrics'}

openshift_hosted_logging_deployer_version=v3.6.0
openshift_hosted_logging_deploy=true
openshift_hosted_logging_storage_kind=nfs
openshift_hosted_logging_storage_access_modes=['ReadWriteOnce']
openshift_hosted_logging_storage_nfs_directory=/exports
openshift_hosted_logging_storage_nfs_options='*(rw,root_squash)'
openshift_hosted_logging_storage_volume_name=logging
openshift_hosted_logging_storage_volume_size=10Gi
openshift_hosted_logging_storage_labels={'storage': 'logging'}

[masters]
master-1

[etcd]
master-1

[nfs]
infra-1

[nodes]
master-1 openshift_node_labels="{'zone': 'default'}"
infra-1 openshift_node_labels="{'zone': 'default', 'region': 'infra'}"
worker-1 openshift_node_labels="{'zone': 'worker'}"
worker-2 openshift_node_labels="{'zone': 'worker'}"
```

Note: to install logging you need to be able to deploy a pod that requests 8GB RAM. 

Run the installer:

```
ansible-playbook -i inventory-file openshift-ansible/playbooks/byo/config.yml
`

If it fails or you want to uninstall do this:

```
ansible-playbook -i inventory-file openshift-ansible/playbooks/adhoc/uninstall.yml
```

To run some checks SSH to the master and run this:

```
sudo oc adm diagnostics
```

NOTE: some of the errors and warnings you see will be false alarms. But if there are real problems you
should see them. 

## Issues

### Logging fails to start

Seems to be an issue with the elasticsearch image. See https://github.com/openshift/openshift-ansible/issues/5497

To fix this manually update the logging-es-data-master deployment in the logging project and update the image tag to
docker.io/openshift/origin-logging-elasticsearch:latest


