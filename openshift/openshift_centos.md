# Installing Openshift Origin on a Centos Machine

This recipe describes how to set up Openshift origin on a Centos7 maching running on Amazon EC2. It is suitable for medium 
term experimentations among a group of users in a reasonably secure manner.

Being based on a single server it is not suitable for highly available or highly scaleable setups.



# Create a centos machine

On AWS subscribe to this image: https://aws.amazon.com/marketplace/pp/B00O7WM7QW?ref=cns_srchrow
A t2.xlarge machine seems to work fine for experimentation. This has 4 cores and 16GB RAM. Running with less than 8GB RAM is unlikely 
to work.
It’s necessary to assign an permanent IP address.
Other centos images (e.g. the one on Scaleway) are not identical and may need a slightly different procedure.

Perform the following as root

## Centos setup

Install dependencies

```sh
yum update -y
yum install -y wget git net-tools bind-utils iptables-services bridge-utils bash-completion docker libcgroup-tools
```

Edit /etc/sysconfig/docker and add `--insecure-registry 172.30.0.0/16` to the options. e.g.
OPTIONS='--selinux-enabled --log-driver=journald --signature-verification=false --insecure-registry 172.30.0.0/16'

Start docker
```sh
systemctl enable docker
systemctl start docker
```

Start cgroups 
```sh
systemctl enable  cgconfig.service
systemctl start cgconfig.service
```

## Openshift install

Grab an openshift release from here: https://github.com/openshift/origin/releases
```sh
curl -kL https://github.com/openshift/origin/releases/download/v1.5.0-rc.0/openshift-origin-server-v1.5.0-rc.0-49a4a7a-linux-64bit.tar.gz | tar xvz
```
Add the extracted dir to your path

Run a simple dockerised environment using oc cluster up

Rreate a dir for os data
```sh
mkdir /root/os_data
```

Start openshift (replace FQDN with correct value)
```sh
oc cluster up --routing-suffix=34.204.64.211.nip.io --public-hostname=34.204.64.211.nip.io --host-data-dir=/root/os_data --use-existing-config=true
```

If the ip address changes then the system does not work. TODO - work out how to address this
To re-create with  a new ip address (existing setup is lost):
```sh
cp -r os_data os_data_old
rm -rf .kube
mkdir os_data
oc cluster up --routing-suffix=<new ip>.nip.io --public-hostname=<new ip>.nip.io --host-data-dir=/root/os_data
```

Note S2I builds do not work with these options with the scaleway centos image. Need to wok out how to get this working

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

Callback URL will be line this:
`https://<dns or ip>:8443/oauth2callback/github` 
(where GitHub is the name of the provider in the master-config.yaml file.

For htpasswd file try this:

```sh
yum install -y httpd-tools
htpasswd -c users.htpasswd user1
htpasswd users.htpasswd user2
```

Supported providers are described here: https://docs.openshift.org/latest/install_config/configuring_authentication.html#identity-providers

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


