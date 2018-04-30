# Notes

## Set the timeout when pulling docker images

In the /etc/origin/node/node-config.yaml add thiss to the `kubeletArguments` section:
```
  image-pull-progress-deadline:
  - "10m"
```
The restart the node service:
```
sudo systemctl restart origin-node.service
```

Do this on all nodes.
