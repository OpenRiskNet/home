# OpenShift deployments

The [OKD Orchestrator] is the _preferred_ tool for the formation of
OpenShift VRE deployments. The `standard-openstack` directory seen here
is kept as a historical reference for the early (pre-orchestrator) deployments.
The role of the **OKD Orchestrator** is to provide a simplified
installation process that supports these types of deployments:

* simple one-server deployment for basic experimentation
* standard availability allowing moderate scaleability
* high availability providing a high levels of fault tolerance and scaleability

We anticipate at the very least to support these infrastructures:

* OpenStack - for flexible use and deployment to in-house clusters
* Amazon AWS - for robust cloud production deployments
* Google CE - for robust cloud production deployments
* Bare Metal - for custom/on-premise infrastructure
* Scaleway - for low cost cloud deployments

For further details and an installation guide refer to the
orchestrator's built-in [documentation].

---

[Documentation]: https://docs.informaticsmatters.com/build/html/index.html
[OKD Orchestrator]: https://github.com/InformaticsMatters/okd-orchestrator.git
