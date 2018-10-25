# Cheetsheet for managing GlusterFS

## Useful links

[kekati-cli reference](https://www.systutorials.com/docs/linux/man/8-heketi-cli/)

[some examples](https://access.redhat.com/documentation/en-us/reference_architectures/2017/html/deploying_openshift_container_platform_3.5_on_amazon_web_services/persistent_storage) (this is for AWS but the info is useful)

Info on Ansible playbooks:
* https://github.com/openshift/openshift-ansible/tree/master/roles/openshift_storage_glusterfs
* https://github.com/openshift/openshift-ansible/blob/master/playbooks/openshift-glusterfs/README.md

## Using Hekati

Identify the hekati pod in the glusterfs project.

```
oc rsh <hekati-pod>
```

### Credentials

You need to set the `HEKETI_CLI_USER` and `HEKETI_CLI_KEY` environment variables.
Key can be found in the `heketi-storage-admin-secret` secret.

In the hekati pod:

```
# export HEKETI_CLI_USER=admin
# export HEKETI_CLI_KEY="<key-from-secret>"
#
# hekati-cli help
...
```

### Operations

#### Listing nodes

```
# heketi-cli node list
Id:04aaa7f120cceaa292c1625f6e3c1e18	Cluster:5597e74a79ccb9cef776af8d55af2366
Id:60459e8e6ddc6043a9b6abb16d08c94c	Cluster:5597e74a79ccb9cef776af8d55af2366
Id:83ebf02c6cd32577eb3cde36d2b48e26	Cluster:5597e74a79ccb9cef776af8d55af2366
```

#### Listing topology

```
# heketi-cli topology info
...
```

#### Listing volumes
```
# heketi-cli volume list
...
#  heketi-cli volume info <volume-id>
...
```

## Gluster

To look directly at gluster:

1. `oc rsh` to a gluster pod
2. run a gluster cli command. e.g. `gluster volume list`
3. `gluster help` lists the available commands 

