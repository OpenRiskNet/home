# Installing Minishift on a local machine

See the main docs: https://docs.openshift.org/latest/minishift/getting-started/installing.html

Minishift is a simple “all in one” distribution of Openshift.
Using Minishift is a good way to get started with running OpenShift locally
on your computer. It provides a good way to try it out and learn what it can
do without incurring costs or provisioning servers. Minishiift is not suitable
for production use.

_TODO_ - add instruction for getting running on Windoze

A machine with 8GB RAM is probably the minimum. The default local cluster
will result in the creation of one VM using 2 cores, 20GiB disk image space
and 2GB RAM. With only this don’t try to deploy too much, or expect too much
from the OpenShift logging and metrics services etc.

>	In order to run minishift it needs a hypervisor to start the virtual machines
	that it will create. You therefore need to make sure that your hypervisor of choice
	is installed and enabled before you execute `minishift start` later in this guide.
	A number are available. The default VM it uses is `xhyve` but you can also
	use `VirtualBox` or `VMWare Fusion`, amongst others. Installation 

>	This guide has been verified with `xhyve` (using the latest/HEAD commit 
	from 9th August 2016) and `VirtualBox` (v1.5.26) on macOS Sierra. 

>	This guide has been verified with `Chrome` v 60.0.3112.113 on macOS Sierra.
	There appear to be stability issues with the Safari browser (using
	v10.1.2 on macOS Sierra) so, at the moment, the best advice is to use Chrome.
	
To install `xhyve` on OSX you can use `brew` to install both it and the Docker
machine driver:

```
$ brew install --HEAD xhyve
```

then follow instructions in _setting up the driver plugin_ for xhyve at
https://docs.openshift.org/latest/minishift/getting-started/setting-up-driver-plugin.html

...which essentially requires you to also install the driver using brew...

```
$ brew install docker-machine-driver-xhyve
```

...and then adjust some fiel attributes...

```
$ sudo chown root:wheel $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
$ sudo chmod u+s $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
```
Download minishift from here: https://github.com/minishift/minishift/releases

_TODO_ - add instructions for users of `brew` on OSX

Unpack it and place the `minishift` binary in a suitable directory
(i.e. `~/bin/minishift`) and add the directory to your PATH. 

```sh
minishift version
```

Check all looks good. The next step will not only start minishift but
also download more material and utilities.

## Starting the minishift service

Start minishift (with the default `xhyve` hypervisor):
```sh
$ minishift start
```

Or, to start with `VirtualBox`:
```sh
$ minishift start --vm-driver virtualbox
```

This starts a minishift _cluster_ and minishift will download a number of files.
Depending on the speed of your internet connection, it may take  a number of
minutes to complete. Once started you should see the following summary
written to stdout:

```
OpenShift server started.

The server is accessible via web console at:
	https://192.168.99.100:8443

You are logged in as:
	User:     developer
	Password: <any value>

To login as administrator:
	oc login -u system:admin
```

>	Minishift installes material to `~/.minishift` and `~/.kube` directories,
	which it will create. You will find the `oc` binary that has been downloaded
	(probably in `.minishift/cache/oc/v3.6.0/`). This directory
	needs to be added to your `PATH`. The actual path is reported with the
	convenient command `minishift oc-env`.

>	Add this the path to your PATH or follow the `minishift oc-env` instructions
	to add it to your existing shell, e.g. `eval $(minishift oc-env)`.
  
The URL to open for the web console was be reported when you started minishift's
cluster. You can login with any non-empty username and password
(clearly this is not designed to be secure, just to allow easy experimentation)
but if you go with:

```
username: developer
password: <anything non empty>
```

...you get a user that can create projects directly.

You can experiment with start options, which can be seen with the following
command:

```sh
$ minishift start --help
```

You can create a larger VM with the `--cpu` and `--memory` options.

## Stopping (suspending) the minishift service

Stopping Minishift:
```sh
$ minishift stop
```

The service is simply suspended in the VM allowing you to quickly restart it
without the overhead of reconstructing the VM. In order to remove the VM
you will need to delete the minishift service.

## Deleting the minishift service

Deleting everything, including the VM it created, in order to start again:
```sh
minishift delete
```

To really delete absolutely everything delete the `~/.kube` (bits of Kubernetes
that minishift relies on) and `~/.minishift` directories.

## Minishift service status

Getting minishift status:
```sh
$ minishift status
```

*	When deleted you should see it respond with `Does Not Exist`.
*	When the minishift cluster is running it should respond with `Running`.

## Configuring a hostname and routing
You should provide a name that can be resolved by the minishift cluster.
This should be set in your `/etc/hosts` and should be the address of the
hypervisor.

So, if your `VirtualBox` hypervisor IP is `192.168.99.1`, add it along with
a suitable `.local` hostname to your `/etc/hosts`:
```
192.168.99.1	virtualbox.local
```

With an entry in `/etc/hosts` you can start your minishift service and provide usable
hostname and routing capabilities. the following starts a service with
4 cores and 8GB RAM using VirtualBox (the line is wrapped for clarity):

```
$ minishift start
	--vm-driver virtualbox
	--routing-suffix virtualbox.local
	--public-hostname virtualbox.local
	--memory 8GB
	--cpus 4
```

# Troubleshooting

1. Unknown authority

I see `Error: The server uses a certificate signed by unknown authority.`
when I try to start the service.
	
This might be the result of of prior service execution.
Execute `minishift delete --clear-cache` and then try starting
the service again.
