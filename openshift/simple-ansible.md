# Create a simple 2 node Openshift installation using the Ansible installer

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

Full log file is in [this gist](https://gist.github.com/tdudgeon/a6f32bdf8dafb80747581cef6ccfac4b).


## After installation

### On master

```
oc get nodes
NAME                                                           STATUS    AGE       VERSION
c21a833e-6c52-4217-8c63-88735c8f2453.priv.cloud.scaleway.com   Ready     13m       v1.6.1+5115d708d7
```
**Note:** node has not joined cluster


```
oc get all
NAME                  DOCKER REPO                                                 TAGS      UPDATED
is/registry-console   docker-registry.default.svc:5000/default/registry-console   latest    8 minutes ago

NAME                  REVISION   DESIRED   CURRENT   TRIGGERED BY
dc/docker-registry    1          1         1         config
dc/registry-console   1          1         1         config
dc/router             1          1         1         config

NAME                    DESIRED   CURRENT   READY     AGE
rc/docker-registry-1    1         1         1         9m
rc/registry-console-1   1         1         1         8m
rc/router-1             1         1         1         11m

NAME                      HOST/PORT                                                   PATH      SERVICES           PORT      TERMINATION   WILDCARD
routes/docker-registry    docker-registry-default.router.default.svc.cluster.local              docker-registry    <all>     passthrough   None
routes/registry-console   registry-console-default.router.default.svc.cluster.local             registry-console   <all>     passthrough   None

NAME                   CLUSTER-IP       EXTERNAL-IP   PORT(S)                   AGE
svc/docker-registry    172.30.158.245   <none>        5000/TCP                  10m
svc/kubernetes         172.30.0.1       <none>        443/TCP,53/UDP,53/TCP     20m
svc/registry-console   172.30.212.224   <none>        9000/TCP                  8m
svc/router             172.30.185.203   <none>        80/TCP,443/TCP,1936/TCP   11m

NAME                          READY     STATUS    RESTARTS   AGE
po/docker-registry-1-hxmkm    1/1       Running   0          9m
po/registry-console-1-6kz4q   1/1       Running   0          8m
po/router-1-d864w             1/1       Running   0          10m
```

```
docker images
REPOSITORY                                   TAG                 IMAGE ID            CREATED             SIZE
docker.io/cockpit/kubernetes                 latest              ee4db2cbaafc        11 days ago         407.6 MB
docker.io/openshift/origin-deployer          v3.6.0              ad03ec44312c        13 days ago         974.2 MB
docker.io/openshift/origin-docker-registry   v3.6.0              ec456625b2a0        13 days ago         1.062 GB
docker.io/openshift/origin-haproxy-router    v3.6.0              75e805233369        13 days ago         995.3 MB
docker.io/openshift/origin-pod               v3.6.0              fb52c4c8f037        13 days ago         213.4 MB
```

```
systemctl list-units --all | grep -i origin
  var-lib-origin-openshift.local.volumes-pods-8a973591\x2d81c1\x2d11e7\x2dbe9e\x2dde198c19e002-volumes-kubernetes.io\x7esecret-router\x2dtoken\x2dt1lc2.mount   loaded    active   mounted   /var/lib/origin/openshift.local.volumes/pods/8a973591-81c1-11e7-be9e-de198c19e002/volumes/kubernetes.io~secret/router-token-t1lc2
  var-lib-origin-openshift.local.volumes-pods-8a973591\x2d81c1\x2d11e7\x2dbe9e\x2dde198c19e002-volumes-kubernetes.io\x7esecret-server\x2dcertificate.mount      loaded    active   mounted   /var/lib/origin/openshift.local.volumes/pods/8a973591-81c1-11e7-be9e-de198c19e002/volumes/kubernetes.io~secret/server-certificate
  var-lib-origin-openshift.local.volumes-pods-acd305e9\x2d81c1\x2d11e7\x2dbe9e\x2dde198c19e002-volumes-kubernetes.io\x7esecret-registry\x2dcertificates.mount   loaded    active   mounted   /var/lib/origin/openshift.local.volumes/pods/acd305e9-81c1-11e7-be9e-de198c19e002/volumes/kubernetes.io~secret/registry-certificates
  var-lib-origin-openshift.local.volumes-pods-acd305e9\x2d81c1\x2d11e7\x2dbe9e\x2dde198c19e002-volumes-kubernetes.io\x7esecret-registry\x2dtoken\x2dzsvn6.mount loaded    active   mounted   /var/lib/origin/openshift.local.volumes/pods/acd305e9-81c1-11e7-be9e-de198c19e002/volumes/kubernetes.io~secret/registry-token-zsvn6
  var-lib-origin-openshift.local.volumes-pods-d158bd64\x2d81c1\x2d11e7\x2dbe9e\x2dde198c19e002-volumes-kubernetes.io\x7esecret-default\x2dtoken\x2dbt694.mount  loaded    active   mounted   /var/lib/origin/openshift.local.volumes/pods/d158bd64-81c1-11e7-be9e-de198c19e002/volumes/kubernetes.io~secret/default-token-bt694
  origin-master-api.service                                                                                                                                     loaded    active   running   Atomic OpenShift Master API
  origin-master-controllers.service                                                                                                                             loaded    active   running   Atomic OpenShift Master Controllers
  origin-node.service                                                                                                                                           loaded    active   running   OpenShift Node
```

### On node

```
docker images
REPOSITORY                                   TAG                 IMAGE ID            CREATED             SIZE
docker.io/cockpit/kubernetes                 latest              ee4db2cbaafc        11 days ago         407.6 MB
docker.io/openshift/origin-deployer          v3.6.0              ad03ec44312c        13 days ago         974.2 MB
docker.io/openshift/origin-docker-registry   v3.6.0              ec456625b2a0        13 days ago         1.062 GB
docker.io/openshift/origin-haproxy-router    v3.6.0              75e805233369        13 days ago         995.3 MB
docker.io/openshift/origin-pod               v3.6.0              fb52c4c8f037        13 days ago         213.4 MB
```

```
systemctl list-units --all | grep -i origin
  var-lib-origin-openshift.local.volumes-pods-8a973591\x2d81c1\x2d11e7\x2dbe9e\x2dde198c19e002-volumes-kubernetes.io\x7esecret-router\x2dtoken\x2dt1lc2.mount   loaded    active   mounted   /var/lib/origin/openshift.local.volumes/pods/8a973591-81c1-11e7-be9e-de198c19e002/volumes/kubernetes.io~secret/router-token-t1lc2
  var-lib-origin-openshift.local.volumes-pods-8a973591\x2d81c1\x2d11e7\x2dbe9e\x2dde198c19e002-volumes-kubernetes.io\x7esecret-server\x2dcertificate.mount      loaded    active   mounted   /var/lib/origin/openshift.local.volumes/pods/8a973591-81c1-11e7-be9e-de198c19e002/volumes/kubernetes.io~secret/server-certificate
  var-lib-origin-openshift.local.volumes-pods-acd305e9\x2d81c1\x2d11e7\x2dbe9e\x2dde198c19e002-volumes-kubernetes.io\x7esecret-registry\x2dcertificates.mount   loaded    active   mounted   /var/lib/origin/openshift.local.volumes/pods/acd305e9-81c1-11e7-be9e-de198c19e002/volumes/kubernetes.io~secret/registry-certificates
  var-lib-origin-openshift.local.volumes-pods-acd305e9\x2d81c1\x2d11e7\x2dbe9e\x2dde198c19e002-volumes-kubernetes.io\x7esecret-registry\x2dtoken\x2dzsvn6.mount loaded    active   mounted   /var/lib/origin/openshift.local.volumes/pods/acd305e9-81c1-11e7-be9e-de198c19e002/volumes/kubernetes.io~secret/registry-token-zsvn6
  var-lib-origin-openshift.local.volumes-pods-d158bd64\x2d81c1\x2d11e7\x2dbe9e\x2dde198c19e002-volumes-kubernetes.io\x7esecret-default\x2dtoken\x2dbt694.mount  loaded    active   mounted   /var/lib/origin/openshift.local.volumes/pods/d158bd64-81c1-11e7-be9e-de198c19e002/volumes/kubernetes.io~secret/default-token-bt694
  origin-node.service                                                                                                                                           loaded    active   running   OpenShift Node
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



