# Installing Openshift Origin on a Centos Machine

This recipe describes how to set up Openshift origin on a Centos7 maching running on Amazon EC2. It is suitable for medium 
term experimentations among a group of users in a reasonably secure manner.

Being based on a single server it is not suitable for highly available or highly scaleable setups.

# Create a centos machine

On AWS subscribe to this image: https://aws.amazon.com/marketplace/pp/B00O7WM7QW?ref=cns_srchrow
A t2.xlarge machine seems to work fine for experimentation. This has 4 cores and 16GB RAM. Running with less than 8GB RAM is unlikely to work.
It’s necessary to assign an permanent IP address.
Other centos images (e.g. the one on Scaleway) are not identical and may need a slightly different procedure.

Perform the following as root

## Centos setup

### Install dependencies

```sh
yum update -y
yum install -y wget git net-tools bind-utils iptables-services bridge-utils bash-completion docker libcgroup-tools
```

Edit /etc/sysconfig/docker and uncomment the INSECURE_REGISTRY option so that it looks like this:

INSECURE_REGISTRY='--insecure-registry 172.30.0.0/16'

### Start docker

```sh
systemctl enable docker
systemctl start docker
```

### Start cgroups 

```sh
systemctl enable  cgconfig.service
systemctl start cgconfig.service
```

## Openshift install

Grab an openshift release from here: https://github.com/openshift/origin/releases
```sh
curl -kL https://github.com/openshift/origin/releases/download/v3.6.0-rc.0/openshift-origin-server-v3.6.0-rc.0-98b3d56-linux-64bit.tar.gz | tar xvz
```
Add the extracted dir to your path (edit .bash_profile).

## Run a simple dockerised environment using oc cluster up

Create a dir for OpenShift data
```sh
mkdir /root/os_data
```

Start openshift (replace FQDN with correct value)
```sh
oc cluster up --routing-suffix=34.204.64.211.nip.io --public-hostname=34.204.64.211.nip.io --host-data-dir=/root/os_data --use-existing-config=true
```
Note: using nip.io (or similar) works fine for testing, but you will not be able to generate certificates for a domain
like this so for more long running setups set up a proper domain name.

If the FQDN changes then the system does not work. TODO - work out how to address this
To re-create with a new FQDN (existing setup is lost):
```sh
mv os_data os_data_old
rm -rf .kube
mkdir os_data
oc cluster up --routing-suffix=<new fqdn>.nip.io --public-hostname=<new fqdn> --host-data-dir=/root/os_data --use-existing-config=true
```
Note: the --use-existing-config=true option is optional.

Note: S2I builds do not work with these options with the Scaleway centos image. Need to wok out how to get this working.

## Authentication

By default any non-null username and password is allowed.
To change this edit the oauthConfig/identityProviders in /var/lib/origin/openshift.local.config/master/master-config.yaml and restart.
identifyProviders section will look like this:

```yaml
oauthConfig:
  alwaysShowProviderSelection: false
  assetPublicURL: https://<insert here>.nip.io:8443/console/
  grantConfig:
    method: auto
    serviceAccountMethod: prompt
  identityProviders:
  - name: htpasswd
    challenge: true
    login: true
    mappingMethod: claim
    provider:
      apiVersion: v1
      kind: HTPasswdPasswordIdentityProvider
      file: users.htpasswd
  - name: github
    challenge: false
    login: true
    mappingMethod: claim
    provider:
      apiVersion: v1
      kind: GitHubIdentityProvider
      clientID: <insert here>
      clientSecret: <insert here>
      organizations:
      - InformaticsMatters
```

### For GitHub auth

Set up an OAUTH app in your GitHub organisation.

The callback URL will be line this:
`https://<fqdn or ip>:8443/oauth2callback/github` 
(where GitHub is the name of the provider in the master-config.yaml file.

For htpasswd file try this (the users.htpasswd file must be put in /var/lib/origin/openshift.local.config/master/):

```sh
yum install -y httpd-tools
htpasswd -c users.htpasswd user1
htpasswd users.htpasswd user2
```

Supported providers are described here: https://docs.openshift.org/latest/install_config/configuring_authentication.html#identity-providers

When tightening security you need to consider the OpenShift system:admin user. This is the user that has full 
admin rights across the cluster. If you are logged in as the Linux root user you can login to the cluster
as this user:

```sh
oc login -u system:admin
```

However, if you are not the root user then you cannot do this (the login process will try to authenticate the
system:admin user against your configured providers). Instead you should add the necessary rights to a user 
that is authenticated by one of the providers. Two ways of doing this are (change admin for whichever user you
are wanting to grant these privs):

```sh
oc adm policy add-cluster-role-to-user cluster-admin admin
```
This method grants cluster-admin role to that use, effectively giving them full access.
A safer approach is:


```sh
oc adm add-cluster-role-to-user sudoer admin1
```
This grants sudoer role to your user so that they can imporsonate the system:admin user using the --as flag. e.g.

```sh
oc get -n default po --as=system:admin
```

## Server management

Shutdown the cluster:

```sh
oc cluster down
```

Start the cluster:

```sh
oc cluster up --routing-suffix=107.23.89.150.nip.io --public-hostname=107.23.89.150.nip.io --host-data-dir=/root/os_data --use-existing-config=true
```
Get cluster status:

```sh
oc cluster status
```


