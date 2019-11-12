# Getting any Docker image running (in OpenShift)

## Background
Quite often you may be required to run container images that you don't control,
database containers is one typical example. Often these containers demand more
from the default 'restricted' privilege of the the project's owner and/or its
service account (i.e. the ability to run root-level command like changing
file ownership or permissions). Without _special steps_ your containers
are likely to end up crashing (because they're prevented from running such
commands) and entering a _crash loop backup_ cycle.

## Solution
So we know why it failed, how do we fix this?

Well ideally we fix the original docker image to not run as root.
If this is not possible then we can tell OpenShift, using a user with `admin`
privilege, to allow this project to run as root using the below command to
change the security context constraints:

    $ oc project <PROJECT>
    $ oc aadm policy add-scc-to-user anyuid -z default

Alternatively, as `admin`, you can edit the anyuid security context, adding the
project and its `default` service account to the `users:` section
using the command: -

    $ oc edit scc anyuid

For example, if `jaqpot` runs with the service account `jaqpot` you's add
the following line: -

    - system:serviceaccount:jaqpot:jaqpot

>   For more details of the problem and the above command refer to the
    OpenShift blog article "[getting-any-docker-image-running] in your own
    OpenShift cluster".

---

[getting-any-docker-image-running]: https://blog.openshift.com/getting-any-docker-image-running-in-your-own-openshift-cluster/
