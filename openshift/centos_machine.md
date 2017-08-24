# Centos machine setup

To create a base machine for OpenShift.

Create a machine from a Centos 7.3 image. 
For AWS look [here](https://wiki.centos.org/Cloud/AWS) to find the appropriate image.

Then add the following: 


```
yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
yum -y update
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo

yum -y install docker-1.12.6
# skip bit about configuring docker storage
# TODO - work this out for prod
systemctl enable docker
systemctl start docker

yum -y install NetworkManager
systemctl enable NetworkManager
systemctl start NetworkManager
```

Best to prepare a snapshot of this images to avoid re-doing this each time.

If needing Ansible also do this:

```
yum -y --enablerepo=epel install ansible pyOpenSSL
```
