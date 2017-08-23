# Centos machine setup

To create a base machine for OpenShift.

Create a machine from a Centos 7.3 image and then add the following: 

```
yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct epel-release
yum -y update
yum -y install docker

# skip bit about configuring docker storage
# TODO - work this out for prod

systemctl enable docker
systemctl start docker

yum -y install NetworkManager
systemctl enable NetworkManager
systemctl start NetworkManager
```

Best to prepare a snapshot of this images to avoid re-doing this each time.
