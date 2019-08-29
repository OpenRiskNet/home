# Project Service Accounts
Service accounts are a Kubernetes/OpenShift mechanism to
provide a flexible way to control API access without sharing a regular
user’s credentials. Each project (namespace) comes with some built-in
service accounts (i.e. `builder`, `deployer` and `default`).

Unless a different service account is named Pods (containers) are
deployed using the built-in `default` service account.

This is normally fine but if your container requires extra privileges,
like the ability to run as root or a specific user ID then the `default`
account is unlikely to be of any use. Under these circumstances you must
run your Container with a project-specific service account with suitable
privilege.

If you think you need a project-specific service account ask the cluster
administrator to create your project with a suitble account. This normally
requires the following cluster command actions: -

    $ oc project <project>
    $ oc create serviceaccount <project>
    $ oc adm policy add-scc-to-user anyuid -z <project>
    
Once done you can then name the service account in your Pod definition.
For a `DeploymentConfig` you'd add the `serviceAccountName` declaration,
a template definition (edited for clarity) will look like this: - 

    parameters:
    
    - name: APP_SA
      value: bridgedb
    
    objects:
    
    - kind: DeploymentConfig
      apiVersion: v1
      spec:
        template:
          spec:
            serviceAccountName: ${APP_SA}
