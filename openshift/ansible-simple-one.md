# EC2, Ansible core, one OpenShift node
Create a simple single-node Openshift installation using the Ansible installer.

Here we'll be creating a central Ansible server and one that will be provisioned
from the Ansible server as a single OpenShift node. The OpenShift node will
act both as master and a node on which applications can be deployed.
This is not a typical installation but it is simple and functional.

*   We will need two server instances
*   The servers will reside on Amazon's _Elastic Compute Cloud_ (EC2).
*   This guide assumes that you have an account on Amazon AWS and therefore
    does not describe setting up the account.

# Preparing your Amazon EC2 instances

## Creating a Virtual Private Cloud
>   In order to use your own isolated services you will need to create your own
    Virtual Private Cloud (**VPC**). Create a VPC using the VPC service
    under the _Networking & Content Delivery_ group of services.

From here click the `Start VPC Wizard` button.

**Step 1: Select a VPC Configuration**. Here we just need the simplest
`VPC with a Single Public Subnet`. Hit the **Select** button.

**Step 2: VPC with a Single Public Subnet**. Provide a name, i.e. `openshift-one`.
and then hit **Create VPC**. After a few moments you should be returned to the
VPC table displaying your VPC.

## Creating a Security Group
>   By default, Amazon EC2 associates your instances with a security group that
    allows no inbound traffic. You can create a security group that allows your
    EC2 instances to accept the traffic that you expect.
    
Return to the VPC dashboard and select **Security Groups** from the resource
list and click the **Create Security Group** button. Provide the groug with
a name (i.e. `openshift-one`), and a description (i.e. `Basic Security Settings`).
The security group's VPC should be the VPC you created in the step above. It
will be available in the drop-down list of VPCs.

Add the essential Inbound Rules to the group. We need:-

* Type: `HTTP (80)`, Source: `0.0.0.0/0`, 
* Type: `HTTPS (443)`, Source: `0.0.0.0/0`
* Type: `SSH (22)`, Source: `0.0.0.0/0`
* Type: `Custom TCP Rule`, Source: `0.0.0.0/0`

Once done save the rules.

## Creating compute instances
We need two (one for Ansible, one for the OpenShift host). Goto the
**EC2 Dashboard** and click the **Launch Instance** button. You are then
guided through a number of steps before the server instance gets created.

Firstly, let's creatie the instance that will act as our Ansible host that
will be used to configure the 2nd (OpenShift) server instance.

### Step 1: Choose the Amazon Machine Image (AMI)
Here we start with a pre-configured OpenRiskNet operating system image.

*   Select **Community AMIs** from the sidebar
*   In the search-box enter `orn-os-02` and hit return. You should be presented
    with one image. Hit its **Select** button.

### Step 2: Choose Instance Type
Here we only need a small image.

*   Select `t2.micro`
*   Hit the **Next: Configure Instance Details** button (botton-right-hand corner)

### Step3: Configure Instance Details

*   Select the VPC you created earlier, i.e. `openshift-one` for the **Network**
*   And `Enable` the **Auto-assign Public IP**
*   You can leave the **IAM role** blank.

Hit **Next: Add Storage**

### Step 4: Add Storage

*   Enter `32` for **Size (GiB)**
*   And `General Purpose SSD (GP2)` for **Volume Type**
*   Click the **Delete on Termination** checkbox so that it's removed when
    the server instance is deleted.

Hit **Next: Add Tags**

### Step 5: Add Tags
To simplify its identification you can add a tag, for now use sometihing
distinct like `openshift-one-ansible` and click **Next: Configure Security Group**

### Step 6: Configure Security Group
Click **Select an existing security group** and select the group you created earlier,
(i.e. `openshift-one`) before hitting **Review and Launch**. Review the
instance summary and then click **Launch** in the bottom-right-hand corner
of the page.

Just prior to launching you wil be given the opportunity to provide or create
an SSH pubic and private key pair that you store so that you can SSH to your
server. If you have an existing key pair use that or select **Create a new key pair**
and give it a name i.e. `osone` and then click the **Download Key Pair**
button to get the private key file.

Once downloaded this file (probably called `osone.pem.txt`)
should be placed in your `~/.ssh` and renamed `osone.pem`.

Remember that the access permissions of the file need to be set correctly:

    $ chmod 600 ~/.ssh/osone.pem
    
With that done you should now hit the **Launch Instances** button of the
key-pair dialogue box.

After a short while your instance should be running and you should be able
to SSH to it via its public IP address, which you'll be able to find
using the **EC2 Dashboard**.

>   If your instance doesn't have a name you can give it one via the dashboard.
    For clarity, name it `openshift-one-ansible`.

### Connect to the server    
Try to SSH to your instance using the public IP (this example is obviously
for `34.253.229.228`) using your copy of the SSH key pair you
created for the instance. The user (`centos`) is a built-in part of the original
instance image.

    $ ssh -i ~/.ssh/osone.pem centos@34.253.229.228
    
If successful you'll pass the SSH challenge and you just need to respond
with `yes`:

    The authenticity of host '34.253.229.228 (34.253.229.228)' can't be established.
    ECDSA key fingerprint is SHA256:Qjhp22K72RudyNt3ogYAuEJf8TUq5HjgKUaqyByUSBw.
    Are you sure you want to continue connecting (yes/no)? 

>   You should also be able to connect using the instance's
    **Public DNS (IPv4)** value, but for now we've demonstrated basic
    connectivity to the outside world.
    
Brilliant! You're now on the Ansible server. Let's now create an EC2 instance
that will act as our OpenShift server. Keep this SSH session, you'll need it
later.

Repeat the above steps (1..6) in order to create another server instance to
act as our OpenShift instance, with the following adjustments:

### Step 2: Choose Instance Type
Select a larger image, remember that it wil be running OpenShift and any
applications that we wish to deploy.
    
*   Select `t2.xlarge` (i.e. 16 GiB Memory)

### Step 4: Add Storage
Storage will depend on applications you intend to run so select something useful,
say 40-80GiB and, again selecting SSD.

>   Remember to click the **Delete on Termination** checkbox so that it's
    removed when the server instance is.

### Step 5: Add Tags
Distinguish this from the Ansible server with a name like
`openshift-one-master`.

>   When you launch the instance and are prompted for SSH keys, select
    **Choose and existing key pair** and select the one created earlier
    (i.e. `osone`). Click the checkbox to acknowledge you have access
    to the private key file.

Again, you can give the instance a name from the **EC2 Dashboard**.
Use something distinct like `openshift-one-master`.

## Elastic IP address
>   An Elastic IP address is a static IPv4 address designed for dynamic cloud
    computing. An Elastic IP address is associated with your AWS account.
    With an Elastic IP address, you can mask the failure of an instance or
    software by rapidly remapping the address to another instance in your account.

You can either re-assign an elastic IP address (by choosing `Associate Address`
from the **Actions** list of the Elastic IP dashboard) or cerate a new one
by hitting the **Allocate new address** button.

If you're creating a new address, select the **VPC** as the scope.
Once allocated you need to attach it to an instance via the dashboard.
Select `Associate Address` from the **Actions** list and set the following:

*   Resource type: `Instance`
*   Instance: The instance of what will become the OpenShift server,
    i.e. our `openshift-one-master`.

Now we can resturn to our running Ansible server session
and initiate the deployment of OpenShift to the 2nd server.

# Preparing the Ansible server
A few things need to be setup on the Ansible server before we can
start the deployment of OpenShift to the 2nd server.

### Copy your SSH key file
You need to copy the `.pem` file created for your EC2 instances
from your desktop to the Ansible server. Replace the IP in the following
example with the one assigned to your Ansible EC2 instance.

    $ scp -i .ssh/osone.pem .ssh/osone.pem centos@34.253.229.228:.ssh/osone.pem

### Adjust the Ansible server
Login to the Ansible server instance if you need to...

    $ ssh -i .ssh/osone.pem centos@34.253.229.228
    
Then, on the server install a few packages...

    $ sudo yum -y --enablerepo=epel install ansible \
            pyOpenSSL java-1.8.0-openjdk-headless httpd-tools

(...this might take a few minutes)

### Clone the Ansible Git repo
On your Ansible server...

    $ git clone https://github.com/openshift/openshift-ansible.git
    
### Adjust your domain
If you have a domain you can create a human-readable form of the IP address
(i.e. `openshift.informaticsmatters.com`) and assign it to the Elastic IP address
using your provider tools.

### Create the OpenShift inventory file
This file, used by Ansible, defines the configuration of the OpenShift
server that it will setup. An example is illustrated below:

On your Ansible server...

*   Create a a file (`~/osone-inventory.txt`) and replace instances of
    **ip-10-0-0-170.eu-west-1.compute.internal** in the example below
    with the **Private DNS** address Amazon assigned to _your_ 2nd
    (`openshift-one-master`) server. 

*   Replace `abc.informaticsmatters.com` with your own DNS name
 
```
# Create an OSEv3 group that contains the masters and nodes groups
[OSEv3:children]
masters
nodes

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
# SSH user, this user should allow ssh based auth without requiring a password
ansible_ssh_user=centos
ansible_become=yes
openshift_deployment_type=origin
openshift_release=v3.6
openshift_disable_check=docker_storage,memory_availability,disk_availability

openshift_master_cluster_public_hostname=abc.informaticsmatters.com
openshift_master_default_subdomain=abc.informaticsmatters.com
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/users.htpasswd'}]
# make sure this htpasswd file exists
openshift_master_htpasswd_file=/home/centos/users.htpasswd

# host group for masters
[masters]
ip-10-0-0-170.eu-west-1.compute.internal

# host group for etcd
[etcd]
ip-10-0-0-170.eu-west-1.compute.internal

# host group for nodes,
[nodes]
ip-10-0-0-170.eu-west-1.compute.internal openshift_node_labels="{'region': 'infra'}" openshift_schedulable=true
```

### Create user passwords
>   This file, that you create on the Ansible server, will be transferred
    to the OneShift server by Ansible. The password you provide will form the
    basis of the OpenShift console user login on the 2nd server.

Create a `developer` user, and assign (and remember) a suitable password.
From the user's home directory run...

    $ htpasswd -c users.htpasswd developer
    New password: 
    Re-type new password: 
    Adding password for user developer

This will create a `users.htpasswd` file.

### Create an Ansible configuration file
Create an `ansible.cfg` file in the root directory of the Ansible server
instance with the following contents:

```
[defaults]
host_key_checking=False
hostfile=osone-inventory.txt
remote_user=centos
forks = 20
gathering = smart
fact_caching = jsonfile
fact_caching_connection = $HOME/ansible/facts
fact_caching_timeout = 600
log_path = $HOME/ansible.log
nocows = 1
callback_whitelist = profile_tasks

[ssh_connection]
pipelining=True
```

>   If you used a different name for your inventory file from the earlier step
    change the `hostfile=osone-inventory.txt` line in the example.

>   Note: `hostfile` is a deprecated setting since 1.9. You should
    switch to using `inventory` if you can.
    
## Prime the SSH connection
This serves simply to avoid the Ansible installer getting stopped
at the connection stage, it primes the SSH connection from the Ansible server
to the OpenShift server so the Ansible installation can continue
without stopping (hopefully).

From the Ansible server using the **Private DNS** IP address assigned to the
OpenShift server (change the IP address accordingly)...

    $ ssh -i .ssh/osone.pem centos@ip-10-0-0-101.eu-west-1.compute.internal

Once the exchange is over `exit` the session to return you to the Ansible
server.

We're nearly ready to go...
    
## Deploy OpenShift
From your Ansible SSH session you should now be able to setup the 2nd server...

    $ ansible-playbook -i osone-inventory.txt \
        openshift-ansible/playbooks/byo/config.yml \
        --private-key ~/.ssh/osone.pem
        
This takes a few minutes.

If you need to re-assign your **Elastic IP** assignments (`Disassociate` and
then `Associate`), with the OpenShift server that will be running,
now would be a good time to do it.

You should be able to connect to the OpenShift service at the designated
URL (replacing the DNS as appropriate):

    https://abc.informaticsmatters.com:8443

>   Safari on OSX may give you problems connecting to OpenShift. Use Chrome or
    Forefox instead.

Once connected you should be able to login using the `developer` username
and password you set during the **Create user passwords** stage earlier.

In this initial server state you will be presented with the OpenShift Welcome
screen and invited to create a project using the **Create Project** button.

You should probably create a project and launch an application just to make sure
the service is properly configured. You could try the `CDK-Depict` recipe.
