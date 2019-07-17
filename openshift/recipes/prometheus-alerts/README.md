# Setting up Prometheus alerts to notify to a Slack channel

## Login

```
oc login https://prod.openrisknet.org -u admin
oc project openshift-monitoring
```

## Prometheus rules

Using the PrometheusRule CRD create a new Rule (e.g. named `prometheus-extra-rules`) using content such as [prometheus-extra-rules.yaml]().
Do not modify the existing `prometheus-k8s-rules` rules as the Prometheus operator will set this back to the original.

## Slack webhook

Create a new app in your Slack workspace and create a webhook. Make a note of the URL.

## Alert manager

Use the [alertmanager-template.yaml]() file as a template create a file named `alertmanager.yaml`.
You will at least need to edit the webhook URL.

Create alertmanager secret:

```
oc delete secret alertmanager-main
oc create secret generic alertmanager-main --from-file=alertmanager.yaml
```

The change will be picked up automatically.
Alerts should be sent to the specified Slack cahnnel.

