# Create a simple 2 node Openshift installtion using the Ansible installer

**Note:** this is work in progress and not working yet

## Node preparation

Preprare master and node from a centos 7.3 machine on Scaleway like this:
```
yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct epel-release
yum -y update
yum -y install docker NetworkManager

# skip bit about configuring docker storage - do this for prod

systemctl enable docker
systemctl start docker
systemctl enable NetworkManager
systemctl start NetworkManager
```

## Preparation on the Ansible bastion machine

This machine is use to mange the Openshift nodes.

From a centos 7.3 machine on Scaleway
```
yum -y install ansible git curl wget
git clone https://github.com/openshift/openshift-ansible
```

Create ssh key and deploy public key to master and node.

Create Ansible inventory file:

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


# host group for masters
[masters]
MASTER_PRIVATE_FQDN

# host group for etcd
[etcd]
MASTER_PRIVATE_FQDN

# host group for nodes,
[nodes]
MASTER_PRIVATE_FQDN openshift_node_labels="{'region': 'infra'}" openshift_schedulable=true
NODE_PRIVATE_FQDN openshift_node_labels="{'region': 'infra'}"
```

* Note 1: replace MASTER_PUBLIC_FQDN, MASTER_PRIVATE_FQDN and NODE_PRIVATE_FQDN with the appropriate DNS names.
* Note 2: we allow the master to be schedulable for now. For a bigger cluster we would not allow this.
* Note 3: we define both nodes as infrastrucure nodes to allow router and docker repository to be deployed to these

## Run the installer

```
ansible-playbook -i <Path_to_inventory_file> openshift-ansible/playbooks/byo/config.yml

... tons of output taking about 30 mins ...

PLAY RECAP ********************************************************************************************************************************
c21a833e-6c52-4217-8c63-88735c8f2453.priv.cloud.scaleway.com : ok=464  changed=167  unreachable=0    failed=0   
d2a499a9-0fb9-4a44-8921-16ddbc55fb8b.priv.cloud.scaleway.com : ok=163  changed=55   unreachable=0    failed=0   
localhost                  : ok=13   changed=0    unreachable=0    failed=0
```



## TODO 

1. Work out why node is not joining cluster
1. Add athentication (htpasswd initially?)
1. Add custom certificates
1. Configure persistence (glusterfs?)
1. Configure persistence for docker repository (glusterfs?)
1. Add non-infrastructure nodes
1. Add logging
1. Add metrics
1. Define a HA cluster would look like



