# Installing Minishift on a local machine

See the main docs: https://docs.openshift.org/latest/minishift/getting-started/installing.html

Minishift is a simple “all in one” distribution of Openshift.Using Minishift is a good way to get started with running OpenShift locally on your computer. It provides a good way to try it out and learn what it can do without incurring costs or provisioning servers. Minishiift is not suitable for production use.

_TODO_ - add instruction for getting running on Windoze

A machine with 8GB RAM is probably the minimum. With only this don’t try to deploy too much, or setup logging and metrics etc.

>	In order to run minishift it needs a hypervisor to start the virtual machines
	that it will create. You therefore need to make sure that your hypervisor of choice
	is installed and enabled before you execute `minishift start` later in this guide.
	A number are available. The default VM it uses is `xhyve` but you can also
	use `VirtualBox` or `VMWare Fusion`, amongst others. Installation 

>	This guide has been used with `VirtualBox` v1.5.26

_TODO_ - add instructions for installation of `xhyve`.

Download minishift from here: https://github.com/minishift/minishift/releases

Unpack it and place the `minishift` binary in a suitable directory
(i.e. `~/bin/minishift`) and add the directory to your PATH. 

```sh
minishift version
```

Check all looks good. The next step will not only start minishift but
also download more material and utilities.

Start Minishift (with the default `xhyve` hypervisor):
```sh
minishift start
```

Or, to start with `VirtualBox`:
```
minishift start --vm-driver=virtualbox
```

This starts a minishift _cluster_ and minishift will download a number of files.
Depending on the speed of your internet connection, it may take a while.
Once started you should see the following written to stdout:

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

>	Minishift installes material to the `~/.minishift` directory. There you will
	find the `oc` binary that has been downloaded
	(probably something like .minishift/cache/oc/v3.6.0/). This directory
	needs to be and added to your `PATH`. The actual path
	is reported with the command `minishift oc-env`.

>	Add this to your path or follow the instructions to add it to your
	existing shell, e.g. `eval $(minishift oc-env)`.
  
The URL to open for the web console was be reported when you started minishift's
cluster. You can login with any non-empty username and password
(clearly this is not designed to be secure, just to allow easy experimentation)
but if you go with:

```
username: developer
password: <anything non empty>
```

...you get a user that can create projects directly.

Stopping Minishift:
```sh
minishift stop
```

Deleting everything, including the VM it created, in order to start again:
```sh
minishift delete
```

Getting minishift status:
```sh
minishift status
```
When deleted you should see status report `Does Not Exist`.
When the minishift cluster is running it should report `Running`.

To really delete absolutely everything delete the `~/.kube` (the part of Kubernetes
minishift relies on) and `~/.minishift` directories
