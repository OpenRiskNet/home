# Openshift and OpenRiskNet

OpenRiskNet is planning on basing its deployment around Red Hat's OpenShift. This section of the GitHub 
repository aims to help people on the OpenRiskNet project and others to quickly get up to speed.


## What is OpenShift

OpenShift is Red Hat's container orchestration platform. It is based on Kubernetes which is a project led by 
Google that is putting together an Open Source container orchestration platform based on their many years of 
experience with running containers at high scale, using the systems they refer to as Borg. Kubernetes can be
thought of as the next generate of Borg, and OpenShift as Red Hat's distribution of Kubernetes. It adds 
additional developer related services and security features. OpenShift Origin (which is what OpenRiskNet is 
using for development) is RedHat's upstream project from their OpenShift Enterprise commercial version for which
you can get paid support, similar to the way the Red Hat Enterperise Linux (RHEL) is their commercially supported
version of Linux which is based on Fedora. This ability to optionally get commercial support for both the
underlying RHEL and OpenShift Enterpise should make the Virtual Research Environments 
that OpenRiskNet will make available attractive to commercial customers like Biotechs and Pharmaceutical
companies.

## What OpenShift will provide for OpenRiskNet

So what is a "container orchestration platform"? Well, if you think of Linux (or Windows) as your computer's 
operating system, then you can think of Kubernetes as a distributed operating system. It allows jobs and processes
to be run transparently on a cluster of computers without having to worry about how this happens. A key part of how 
it does this is by deploying things as containers. 
The container is created from an image that defines the containers contents in a way that is transparent to the host
that is executing the container (TODO - link to the section that describes Docker and containers once that is ready).
The container is effectively a black box that executes something, and the host allows the container to be 
executed in a secure and isolated way so that it cannot impact other components running on the host. Kubernetes
provides a complete infrastructure for defining how these containers run, how they can be connected together, how
they can be scaled, how they can be exposed for external access and much much more.

So if Kubernetes provides the distributed operating system for containers, what does OpenShift provide in addition?
Well, if we think of Kubernetes as your distributed operating system then OpenShift is Red Hat's distribution of 
Kubernetes that comes already loaded with the software you want to use as well as strong vetting and handling of 
security making it highly suitable as the platform that OpenRiskNet can provide to customers and users, allowing
them to easily set up their own Virtual Research Environment (VRE) and load whatever chemical safety assessment 
(and other) software that they might want into it. 
OpenShift provides the environment where we can not only build and test these tools, but
also deploy and run them at scale. The customer, or user, might not want to build these themselves (but rather use
Docker images we have already built) but they will want to deploy them to their own environment, which would be their
laptop, their in house servers or anywhere on the cloud. OpenShift's flexible way of deployment means all this is 
possible, and we are not locked in to any particular cloud platform.

The OpenShift _Interactive Learning Portal_ has a number of self-paced scenarios
that use an online pre-configured OpenShift instance. It's an excellent
introduction and allows you to experiment with and learn about OpenShift.

* [Interactive Learning Portal](https://openshift.katacoda.com)

For more information take a look at these links:

* [Docker](http://www.docker.com)
* [Kubernetes](https://kubernetes.io/)
* [Borg: The Predecessor to Kubernetes](http://blog.kubernetes.io/2015/04/borg-predecessor-to-kubernetes.html)
* [Openshift Origin docs](https://docs.openshift.org/latest/welcome/index.html)

And these movies:

* [Kubernetes in 5 mins](https://www.youtube.com/watch?v=PH-2FfFD2PU)
* [OpenShift walk through](https://www.youtube.com/watch?v=yFPYGeKwmpk)
* [Introduction to Openshift Enterprise](https://www.youtube.com/watch?v=W3kTrGgA8YA)

If you find other useful links then please add them.

Take a look at these OpenRiskNet examples that are also in this repository:

* [recipes](recipes/) - training and educational examples
* [environments](environments/) - concrete examples of creating different types of OpenShift environments
* [deployments](deployments/) - concrete examples of deploying infrastructure and application components to OpenShift

Also of interest:

* [Deployment and development guidelines](https://github.com/OpenRiskNet/home/wiki#openrisknet-application-deployments)
