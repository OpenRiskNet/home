# Centos machine setup

To create a base machine for OpenShift.

Create a machine from a Centos 7.3 image. 
For AWS look [here](https://wiki.centos.org/Cloud/AWS) to find the appropriate image.

On Openstack download a centos image from here:
https://cloud.centos.org/centos/7/images/
Choose the qcow2 image format.

The openstack client needed to be present (`pip install openstackclient`) 

Upload the image to Openstack using:
```
openstack image create --file <image-file> <image-name>
```
You will see the new image in the console.


Then add the following using sudo: 


```
yum -y install wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
yum -y update
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
# this is needed as the 3.9 RPMs are not in the standard Centos repos
yum -y install centos-release-openshift-origin

yum -y install docker-1.13.1
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
