# OpenShift Container Probes
OpenShift provide a number of options to detect and handle unhealthy
containers. Two of these [health] mechanisms are handled by the
**Readiness Probe** and the **Liveness Probe**.

They are well documented on the OpenShift [Application Health] page so here
we'll just point out a few helpful hints to get started.

The **Readiness Probe** is used to determine if a container is ready to service
requests. When the probe is unsuccessful OpenShift ensures the container's IP
endpoint reached the container. When it fails the endpoint is removed.

The **Liveness Probe** is used to determine whether a container is still running.
If _this_ probe fails the container is killed and restarted.

Each probe has a number of additional properties: -

-   `initialDelaySeconds`
-   `timeoutSeconds`
-   `periodSeconds`
-   `successThreshold`
-   `failureThreshold`

## Advice
You need to understand the start-up behaviour of your application before
setting these probes as poorly-defined values will result in your Pod being
constantly restarted.

You therefore need to profile it to at least understand how quickly it can
reasonably be expected to provide a service and whether any normal stead-state
behaviour affects the response time of the service being probed. Some
applications execute a significant amount of initialisation before being able
to provide a reliable service, some do not.

The default probe `timeoputSeconds` (the period fo time it takes for the probe
to get a response) is 1 second. Consider 2 to 4 seconds (or any reasonable
value for your application) if the probe request is doing anything other than
just checking an open port.

In all cases you want a responsive container. If the startup is generally
deterministic (and does not depend on external services) then a short
`initialDelaySeconds` that is at least longer than the longest period of
initialisation will suffice. If the application startup
depends on a lot of non-deterministic behaviour, like external database
or disk access, you might need a longer initial delay.

For a responsive startup that accommodates variable delays you can combine a
short `initialDelaySeconds` with a suitable combination of `periodSeconds` and
`failureThreshold`. Using values of `60`, `15` and `8` for the **Liveness**
probe would allow the application to offer a service after 60 seconds but also
allow the probe to fail up to 8 times, accommodating delays of up to 3 minutes
(60 + 15 x 8).

As they run concurrently, when defining both a **Readiness** and **Liveness**
probe, it is unwise to have a combination of **Liveness** settings that
would result in it _firing_ before the **Readiness** Probe. Remember
that the loss of a **Liveness** probe means your container will be restarted.
Often this is avoided by simply having a slightly longer `initialDelaySeconds`
for your **Liveness** probe.
  
---

[Application Health]: https://docs.openshift.com/container-platform/3.7/dev_guide/application_health.html
