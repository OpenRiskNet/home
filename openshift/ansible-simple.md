# Create a simple 2 node Openshift installation using the Ansible installer

## Node preparation

Preprare master and node from a centos 7.3 machine on AWS as decribed in the
[centos_machine.md](centos_machine.md) recipe.


## Preparation on the Ansible bastion machine

This machine is use to manage the Openshift nodes.

From a centos 7.3 machine on AWS in the same VPC as the node machines:
```
yum -y install ansible git curl wget
git clone https://github.com/openshift/openshift-ansible
```

Create ssh key and deploy public key to master and node.

To allow log file to be generated create ansible.cfg in home dir with this:
```
[defaults]
log_path = ~/ansible.log
```

Create Ansible inventory file:

```
# Create an OSEv3 group that contains the masters and nodes groups
[OSEv3:children]
masters
nodes
etcd

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
# SSH user, this user should allow ssh based auth without requiring a password
ansible_ssh_user=centos
ansible_become=yes
openshift_deployment_type=origin
openshift_release=v3.6

# Enable htpasswd authentication
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/users.htpasswd'}]
# make sure this htpasswd file exists
openshift_master_htpasswd_file=/home/centos/users.htpasswd


openshift_disable_check=disk_availability,docker_storage,memory_availability
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
* Note 3: we define both nodes as infrastructure nodes to allow router and docker repository to be deployed to these

## Run the installer

```
ansible-playbook -i <Path_to_inventory_file> openshift-ansible/playbooks/byo/config.yml
```
... tons of output taking about 20 mins ...
```
PLAY RECAP *************************************************************************************************************************************************************************************************************************
ip-10-0-11-69.eu-west-1.compute.internal : ok=160  changed=59   unreachable=0    failed=0   
ip-10-0-96-1.eu-west-1.compute.internal : ok=445  changed=174  unreachable=0    failed=0   
localhost                  : ok=12   changed=0    unreachable=0    failed=0   
```

## After installation

### On master

```
oc get nodes
NAME                                       STATUS    AGE       VERSION
ip-10-0-11-69.eu-west-1.compute.internal   Ready     5m        v1.6.1+5115d708d7
ip-10-0-96-1.eu-west-1.compute.internal    Ready     5m        v1.6.1+5115d708d7
```

```
oc get all
NAME                  DOCKER REPO                                                 TAGS      UPDATED
is/registry-console   docker-registry.default.svc:5000/default/registry-console   latest    23 minutes ago

NAME                  REVISION   DESIRED   CURRENT   TRIGGERED BY
dc/docker-registry    1          1         1         config
dc/registry-console   1          1         1         config
dc/router             1          2         2         config

NAME                    DESIRED   CURRENT   READY     AGE
rc/docker-registry-1    1         1         1         24m
rc/registry-console-1   1         1         1         23m
rc/router-1             2         2         2         27m

NAME                      HOST/PORT                                                   PATH      SERVICES           PORT      TERMINATION   WILDCARD
routes/docker-registry    docker-registry-default.router.default.svc.cluster.local              docker-registry    <all>     passthrough   None
routes/registry-console   registry-console-default.router.default.svc.cluster.local             registry-console   <all>     passthrough   None

NAME                   CLUSTER-IP       EXTERNAL-IP   PORT(S)                   AGE
svc/docker-registry    172.30.171.173   <none>        5000/TCP                  24m
svc/kubernetes         172.30.0.1       <none>        443/TCP,53/UDP,53/TCP     30m
svc/registry-console   172.30.140.122   <none>        9000/TCP                  23m
svc/router             172.30.199.31    <none>        80/TCP,443/TCP,1936/TCP   27m

NAME                          READY     STATUS    RESTARTS   AGE
po/docker-registry-1-75jnn    1/1       Running   0          24m
po/registry-console-1-k2m38   1/1       Running   0          23m
po/router-1-76qrp             1/1       Running   0          26m
po/router-1-cgcb3             1/1       Running   0          26m

```


## TODO 

1. Add custom certificates
1. Configure persistence (glusterfs?)
1. Configure persistence for docker repository
1. Add non-infrastructure nodes
1. Add logging
1. Add metrics
1. Define what a HA cluster would look like



