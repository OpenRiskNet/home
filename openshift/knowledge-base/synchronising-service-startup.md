# Synchronising Service Startup
This technical note provides advice on how the startup of a Pod
can be delayed (synchronised) with the startup of other services or Pods.

## Background
When you start multiple Pods (services) in OpenShift the Pods are started
in no particular order. Pods A, B and C may start in the order B, A and C
for example.

Ideally the Pod application should be developed in such a way
as to avoid dependency on other services so that Pods can be started in any
order and can survive the loss of a dependent service once startup is successful.
These resilient features are time-consuming to implement and test may not be possible,
especially if the Pod has been written by someone else.

## Solution
You can delay the startup of a service container by using an `initContainer`.
An [initContainer] is a short-life container, introduced into your
Pod deployment, that is designed to run until its configured command completes.
InitContainers prevent your Pod container's own initialisation from taking place
until the initContainer command has completed.

You can employ more than one initContainer if your synchronisation is complex
and requires the presence of more than one service. initContainers are started
in the order they are defined and each initContainer must complete before the
next one will start.

A number of [Squonk] application templates use this facility.

---

[initContainer]: https://docs.openshift.org/latest/architecture/core_concepts/pods_and_services.html#pods-services-init-containers
[squonk]: https://github.com/InformaticsMatters/squonk

_Alan Christie  
December 2017_
