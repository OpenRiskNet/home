# Automatic Redeployment of ImageStreams
This technical note provides advice on how to ensure that an application
Pod is redeployed when the source Docker image (assumed to be in DockerHub)
has changed.

## Background
You have setup an application based on an OpenShift catalogue entry based on
an external Docker image but you need it to roll-out and deploy images
automatically when the external Docker image changes.

## Solution
You need to adjust the `ImageStream` and `DeploymentConfig` of your application.
Crucially your `ImageStream` YAML definition must contain a
`dockerImageRepository` declaration and an `importPolicy` in the `tags` section
(remembering to change the image name to the one you’re using):

```
Spec:
  dockerImageRepository: docker.io/alanbchristie/jenkins-slave-docker-centos7
  lookupPolicy:
    local: false
  tags:
    - annotations:
        openshift.io/display-name: Jenkins Docker Slave Image
        slave-label: docker-slave
      From:
        kind: DockerImage
        name: 'docker.io/alanbchristie/jenkins-slave-docker-centos7:latest'
      generation: 5
      importPolicy:
        scheduled: true
      name: latest
      referencePolicy:
        type: Source
```

Additionally you will need to make sure that your `DeploymentConfig` has an
`ImageChangeTrigger`. It is likely to already have a `ConfigChange` trigger,
which causes the deployment to re-deploy the application if you edit the
`DeploymentConfig` itself. You also need an `ImageChange` trigger to re-deploy
of the source image changes (changing the corresponding container and image
names accordingly):

```
triggers:
    - type: "ConfigChange"
    - type: "ImageChange"
      imageChangeParams:
        automatic: true
        containerNames:
          - "helloworld"
        From:
          kind: "ImageStreamTag"
          name: "origin-ruby-sample:latest"
```

You should also make sure that your container’s `imagePullPolicy` in the
`DeploymentConfig` is set to something sensible. If a container’s
`imagePullPolicy` parameter is not specified, OpenShift sets it based on the
image’s tag:

-   If the tag is latest, OpenShift defaults imagePullPolicy to Always.
-   Otherwise, OpenShift defaults imagePullPolicy to IfNotPresent.

So, unless you want something specific set the policy in your container
definition, something like:

```
imagePullPolicy: IfNotPresent
```

For further details you can refer to the official documentation on the topic of
[Builds and Image Streams].

---

[Builds and Image Streams]: https://docs.openshift.com/enterprise/3.0/architecture/core_concepts/builds_and_image_streams.html

_Alan Christie  
December 2017_
