# Understanding how Openshift handles user ids for running containers

Openshift pays specical attention to security, which can cause problems if your containers are not set up to be secure.
Specifically it prefers to avoid running containers as the root user, as this is a well know risk. Well designed images should 
not run as root.

Openshift has a number of settings to control this. To edit the setting edit the Security Context Constraints definition:

```sh
oc login -u system:admin
oc edit scc restricted
```
Look for the runAsUser section and edit the value of the type property. The possible values are:

* MustRunAsRange (default) - Openshift ALWAYS assigns a user id from within a controlled range
* MustRunAsNonRoot - Run as the user defined in the image. If this is root it will fail.
* RunAsAny - Openshift doesn't care, and you are at risk if your image runs as root.

Using RunAsAny allows any contianer to run, but comes with obvious risks.

If using MustRunAsRange (the default) then your container must be able to run as an arbitary non-root ID, NOT the user you specify in 
the Dockerfile. That user will be a member of the root group, so make sure you give suitable read, write, execute permissions to the 
root group. 



