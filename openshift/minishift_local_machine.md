# Installing Minishift on a local machine

See the main docs: https://docs.openshift.org/latest/minishift/getting-started/installing.html

Minishift is a simple “all in one” distribution of Openshift.Using Minishift is a good way to get started with running OpenShift locally on your computer. It provides a good way to try it out and learn what it can do without incurring costs or provisioning servers. Minishiift is not suitable for production use.

_TODO_ - add instruction for getting running on Windoze

A machine with 8GB RAM is probably the minimum. With only this don’t try to deploy too much, or setup logging and metrics etc.
The default VM it use is Xhyve which should be present on a modern version of OSX. 

Download minishift from here: [https://github.com/minishift/minishift/releases]
Download open shift origin client tools from here: [https://github.com/openshift/origin/releases]
Unpack both and add locations to PATH.

Start Minishift:
```sh
minishift start
```
The URL to open for the web console will be reported.
You can login with any non-empty username and password (clearly this is not designed to be secure, just to allow easy experimentation)

Stopping Minishift:
```sh
minishift stop
```

Deleting everything and starting again:
```sh
minishift delete
```
Getting minishift status:
```sh
minishift status
```

To really delete absolutely everything delete the .kube and .minishift directories
