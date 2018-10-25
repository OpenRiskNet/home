# Centos pod for debugging

To fire up a Centos pod that allows you to debug things use a `pod-centos.yaml` file like this:

```
apiVersion: v1
kind: Pod
metadata:
  name: centos
spec:
  containers:
  - name: centos
    image: centos:7
    # Just spin & wait forever
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "while true; do sleep 30; done;" ]
```

Then create the pod using `oc create -f pod-centos.yaml`.

This keeps the pod running forever.
Delete it once you are finished with it.
