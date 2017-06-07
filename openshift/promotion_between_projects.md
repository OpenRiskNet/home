# Building and promoting

This recipe describes how to set up multiple projects (Kubernetes namespaces), build a sample app and promote it between projects.

It assumes you already have an openshift environment running (see recipes for doing this with [minishift](minishift_local_machine.md)
or on a [centos machine](openshift_centos.md)).

We set up 2 projects, development and testing. We create developer and tester users with the developers hading write access to development 
and read access to testing, and testers having write access to testing and read access to development.

A developer builds a sample app in development and tag it for promotion. A tester deploys this tagged image to testing so that it can be 
tested.

A video by RedHat on which this recipe is based can be found
[here](https://www.youtube.com/watch?v=u6LT3efXL_4&list=PLaR6Rq6Z4Iqficb-XqeydZD_ZTD3XEwBp&index=19)

## Setting up users and permissions

Create users developer1, developer2, tester1, tester2. This depends on how secutity is set up. With default security any non-empty 
username and password is allowed so nothing needs to be done. If you have tightened up security add the users by whatever means is 
appropriate e.g. addign them to the htpasswd file.
 
Create development and testing projects
```sh
oc new-project testing --description="Testing environment”
oc new-project development --description="Development environment”
```

Switch to development project
```sh
oc project development
```

Add developers with edit access
```sh
oc policy add-role-to-user edit developer1
oc policy add-role-to-user edit developer2
```

Add testers with view access
```sh
oc policy add-role-to-user view tester1
oc policy add-role-to-user view tester2
```

Switch to testing project
```sh
oc project testing
```

Add testers with edit access
```sh
oc policy add-role-to-user edit tester1
oc policy add-role-to-user edit tester2
```

Add developers with view access
```shoc policy add-role-to-user view developer1
oc policy add-role-to-user view developer2
```

Switch to development project
```sh
oc project development
```

Give testing project image-puller rights to development
```sh
oc policy add-role-to-group system:image-puller system:serviceaccounts:testing -n development
```

Login as developer
```sh
oc login -u developer1
oc project development
```

Build a demo app
```sh
oc new-app centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git
```

Look up the image stream id so that it can be tagged
```sh
oc describe is
```

Tag the image for promotion
```sh
oc tag ruby-ex@sha256:b70b03830f84b7ac51c064db2bccdd85188b1ca9e1e22787015b5d752ce71886 development/ruby-ex:promote
```

Note: in this case its important to use the short name of rate image rather than 172.30.1.1:5000/development/ruby-ex@sha256… so that 
OpenShift just tags the imagestream rather than incorrectly trying to import an image.

Check the tagging
```sh
oc describe is/ruby-ex
```

Change to tester and testing project
```sh
oc login -u tester1
oc project testing
```

Create app from that image
```sh
oc new-app development/ruby-ex:promote
```

## Adding webhook to trigger build in development

Requires the project to be forked etc.

* In the web console oo to builds and locate the relevant build.
* In Configuration section copy the GitHub web hook url
* In GitHub go to the project settings and add new web hook
* Paste in URL. Set content type to application/json. Disable SSL verification.
* Trigger change in GitHub and build in development should start.

TODO - work out how to enable SSL and add a secret
