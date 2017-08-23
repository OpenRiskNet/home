# Simple all-in-one ansible install

This set of recipes create a simple single server openshift installation that has basic (htpasswd) security 
enabled and also allows for provision of Let's Encrypt certificates and metrics.
This is suitable for basic testing purposes but all happens
on a single server so this is not scaleable or highly available.

Ansible is run from the node itself so that Let's Encrypt certificates can be used. 
TODO - work out how to avoid this.

**Note**: If generating certificates do this before running the OpenShift installer so that the ports are free. 

## Setup

### Server

Preprare master and node from a centos 7.3 machine on Scaleway as described in the
[centos_machine.md](centos_machine.md) recipe.

### Extra packages

In addition we need Ansible.

``` 
yum -y install ansible
```

### Network

Setup a DNS entry for your domain (master.example.com is assumed) and a wildcard DNS entry for that 
subdomain (e.g. *.master.example.com).

### Ansible setup

Clone openshift-ansible repo:

```
git clone https://github.com/openshift/openshift-ansible.git
```

Create the Ansible inventory file:

```
# Create an OSEv3 group that contains the masters and nodes groups
[OSEv3:children]
masters
nodes

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
# SSH user, this user should allow ssh based auth without requiring a password
ansible_ssh_user=root
openshift_deployment_type=origin
openshift_disable_check=docker_storage,memory_availability
openshift_hostname=MASTER_PRIVATE_FQDN
openshift_master_cluster_hostname=MASTER_PRIVATE_FQDN
openshift_master_cluster_public_hostname=MASTER_PUBLIC_FQDN
openshift_master_default_subdomain=MASTER_PUBLIC_FQDN
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/users.htpasswd'}]

# host group for masters
[masters]
MASTER_PRIVATE_FQDN ansible_connection=local

# host group for etcd
[etcd]
MASTER_PRIVATE_FQDN ansible_connection=local

# host group for nodes,
[nodes]
MASTER_PRIVATE_FQDN openshift_node_labels="{'region': 'infra'}" openshift_schedulable=true ansible_connection=local
```

* Note 1: replace MASTER_PUBLIC_FQDN and MASTER_PRIVATE_FQDN with the appropriate DNS names.
* Note 2: we allow the master to be schedulable as its the only node.
* Note 3: we define the node as an infrastrucure node to allow router and docker repository to be deployed to these.

To allow log file to be generated create ansible.cfg in home dir with this:
```
[defaults]
log_path = ~/ansible.log
```

### Run installer

```
ansible-playbook -i <Path_to_inventory_file> openshift-ansible/playbooks/byo/config.yml

... tons of output taking about 20 mins ... ending with something like this:

```
PLAY RECAP *****************************************************************************************************************************
a16fdf14-9d63-4fc8-8eb6-c701785a0120.priv.cloud.scaleway.com : ok=422  changed=48   unreachable=0    failed=0   
localhost                  : ok=13   changed=0    unreachable=0    failed=0   
```



### Post install

Add users to the password file:

```
htpasswd /etc/origin/master/users.htpasswd username1
```

Access the web console at https://MASTER_PUBLIC_FQDN:8443
Just because the installer completed and said all was OK does not mean that you have a working cluster.
So check that you can deploy an app. e.g. choose a Node.js app from the Javascript section and deploy the nodejs-ex example app.
 

## Trusted certificates

To avoid the warnings about untrusted certificates we need proper certificates. 
We'll use Let's Encryt as these are free and recognised by all browsers.

**Note:** This does not currently work correctly as an incorrect certificate gets created for the Docker registry.
This appears to be a bug in the ansible script.

### Extra packages

In addition we need Certbot.

``` 
yum -y install certbot
```

### Generate certificates

Before starting on the openshift install generate the Let's Encrypt certificates.
Once DNS has propagated generate the certificates:

```
certbot certonly --standalone -n -m your@email.address --agree-tos -d master.example.com
```

Certificates will be in /etc/letsencrypt/live/master.example.com/


### Ansible setup

Add this to the \[OSEv3:vars\] section of the ansible inventory file

```
openshift_master_named_certificates=[{"certfile": "/etc/letsencrypt/live/master.example.com/fullchain.pem", "keyfile": "/etc/letsencrypt/live/master.example.com/privkey.pem"}]
```

Edit the `openshift_master_cluster_public_hostname` variable to point to the correct public DNS name of your server that
you set in the DNS record (e.g. master.example.com).

### Run installer

```
ansible-playbook -i <Path_to_inventory_file> openshift-ansible/playbooks/byo/config.yml

... tons of output taking about 20 mins ... ending with something like this:

```
PLAY RECAP *****************************************************************************************************************************
ef682b69-de35-4f3e-a5c5-6648e8a2db06.priv.cloud.scaleway.com : ok=454  changed=172  unreachable=0    failed=0
localhost                  : ok=13   changed=0    unreachable=0    failed=0
```

### Post install

Add users to the htpasswd file as before.

Access the web console at https://MASTER_PUBLIC_FQDN:8443.
The site should be recognised as secure with no warning about certificates.
Check that you can deploy a sample app.

### TODOs

* Certificate renewal - write how to do this.
* Handle wildcard certificates once Let's Encrypt provides these (Jan 2018).
* Work out how to handle this if we have multiple masters and a separate Ansible machine


## Install with metrics

This is work in progress. Ignore for now.

### Extra packages

```
yum -y install python-passlib java-1.8.0-openjdk-headless
```


