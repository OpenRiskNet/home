# Install with Metrics and Logging

Adding Logging and Metrics to an Ansible install. This is an extension of 
[ansible-simple.md](ansible-simple.md).

**WARNING:** Metrics is not yet working correctly.

## Ansible machine requirements

You might needs some extra packages on the Ansible machine,
especially if you haven't been through the [Ansible one node](ansible-simple-one.md)
recipe:

```
sudo yum -y install --enablerepo=epel python-passlib 
sudo yum -y install java-1.8.0-openjdk-headless httpd-tools
```

## Base setup

This example uses
* a master machine that also acts as infrastructure node
* one non-infrastructure worker node

NFS is used for logging and metrics persistence.
TODO - repeat this using GlusterFS.

Create a `$HOME/users.htpasswd` file with your users. 

### Ansible inventory file

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

# Enable htpasswd authentication
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/users.htpasswd'}]
# make sure this htpasswd file exists
openshift_master_htpasswd_file=/home/centos/users.htpasswd

openshift_master_cluster_public_hostname=MASTER_PUBLIC_FQDN
openshift_master_default_subdomain=MASTER_PUBLIC_FQDN

openshift_hosted_metrics_deploy=true
openshift_hosted_metrics_deployer_version=v3.6.0
openshift_hosted_metrics_storage_kind=nfs
openshift_hosted_metrics_storage_access_modes=['ReadWriteOnce']
openshift_hosted_metrics_storage_nfs_directory=/exports
openshift_hosted_metrics_storage_nfs_options='*(rw,root_squash)'
openshift_hosted_metrics_storage_volume_name=metrics
openshift_hosted_metrics_storage_volume_size=10Gi
openshift_hosted_metrics_storage_labels={'storage': 'metrics'}

openshift_hosted_logging_deploy=true
openshift_hosted_logging_deployer_version=v3.6.0
openshift_hosted_logging_storage_kind=nfs
openshift_hosted_logging_storage_access_modes=['ReadWriteOnce']
openshift_hosted_logging_storage_nfs_directory=/exports
openshift_hosted_logging_storage_nfs_options='*(rw,root_squash)'
openshift_hosted_logging_storage_volume_name=logging
openshift_hosted_logging_storage_volume_size=10Gi
openshift_hosted_logging_storage_labels={'storage': 'logging'}

[masters]
MASTER_PRIVATE_FQDN

[etcd]
MASTER_PRIVATE_FQDN

[nfs]
MASTER_PRIVATE_FQDN

[nodes]
MASTER_PRIVATE_FQDN openshift_node_labels="{'region': 'infra','zone': 'default'}" openshift_schedulable=true
NODE_PRIVATE_FQDN openshift_node_labels="{'region': 'workers','zone': 'default'}"
```

## Run installer

```
ansible-playbook -i <Path_to_inventory_file> openshift-ansible/playbooks/byo/config.yml
```

... tons of output taking about 20 mins ... ending with something like this:

```
PLAY RECAP *************************************************************************************************************************************************************************************************************************
ip-10-0-208-182.eu-west-1.compute.internal : ok=737  changed=113  unreachable=0    failed=0   
ip-10-0-254-96.eu-west-1.compute.internal : ok=147  changed=12   unreachable=0    failed=0   
localhost                  : ok=13   changed=0    unreachable=0    failed=0
```

SSH to the master and check things are running, remembering that
container creation and service state may take a few minutes to stabilise.

>   You might want to add `admin` privileges to the console user to explore the
    system more fully. As `system:admin` you can do this with a `developer`
    with the commmand `oadm policy add-role-to-user admin developer`.

To inspect the metrics:

```
$ oc get all -n openshift-infra
NAME                      DESIRED   CURRENT   READY     AGE
rc/hawkular-cassandra-1   1         1         0         56m
rc/hawkular-metrics       1         1         0         56m
rc/heapster               1         1         0         56m

NAME                      HOST/PORT                                    PATH      SERVICES           PORT      TERMINATION   WILDCARD
routes/hawkular-metrics   hawkular-metrics.os.informaticsmatters.com             hawkular-metrics   <all>     reencrypt     None

NAME                           CLUSTER-IP       EXTERNAL-IP   PORT(S)                               AGE
svc/hawkular-cassandra         172.30.46.48     <none>        9042/TCP,9160/TCP,7000/TCP,7001/TCP   56m
svc/hawkular-cassandra-nodes   None             <none>        9042/TCP,9160/TCP,7000/TCP,7001/TCP   56m
svc/hawkular-metrics           172.30.221.108   <none>        443/TCP                               56m
svc/heapster                   172.30.109.13    <none>        80/TCP                                56m

NAME                            READY     STATUS              RESTARTS   AGE
po/hawkular-cassandra-1-9wtmq   0/1       ContainerCreating   0          55m
po/hawkular-metrics-g7f2c       0/1       CrashLoopBackOff    6          55m
po/heapster-0f827               0/1       Running             6          55m
```

For logging:

```
$ oc get all -n logging
NAME                                 REVISION   DESIRED   CURRENT   TRIGGERED BY
dc/logging-curator                   1          1         1         config
dc/logging-es-data-master-d108iw7o   1          1         1         config
dc/logging-kibana                    1          1         1         config

NAME                                   DESIRED   CURRENT   READY     AGE
rc/logging-curator-1                   1         1         1         1h
rc/logging-es-data-master-d108iw7o-1   1         1         1         1h
rc/logging-kibana-1                    1         1         1         1h

NAME                    HOST/PORT                          PATH      SERVICES         PORT      TERMINATION          WILDCARD
routes/logging-kibana   kibana.os.informaticsmatters.com             logging-kibana   <all>     reencrypt/Redirect   None

NAME                     CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
svc/logging-es           172.30.80.43    <none>        9200/TCP   1h
svc/logging-es-cluster   172.30.247.30   <none>        9300/TCP   1h
svc/logging-kibana       172.30.238.9    <none>        443/TCP    1h

NAME                                         READY     STATUS    RESTARTS   AGE
po/logging-curator-1-c9r53                   1/1       Running   0          1h
po/logging-es-data-master-d108iw7o-1-63nb7   1/1       Running   0          1h
po/logging-fluentd-nkn83                     1/1       Running   0          1h
po/logging-fluentd-vlln7                     1/1       Running   0          1h
po/logging-kibana-1-dvhhh                    2/2       Running   0          1h
```

>   **IMPORTANT NOTE**: There is currently a bug in the metrics that prevents the `hawkular-metrics` pod from deploying.
    To resolve this use the web console to edit the YAML definition of the hawkular-metrics replication
    controller and change the image version from `latest` to `v3.6.0`. The pod should try to re-deploy and 
    should now start correctly. If not scale it down to 0 and back up to 1 replicas. Once done you should see 
    metrics displayed in the web console alongside your pods.

## Post install

Access Logging at https://kibana.MASTER_PUBLIC_FQDN/

Access Metrics at https://hawkular-metrics.MASTER_PUBLIC_FQDN/hawkular/metrics
