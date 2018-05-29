# Logging in to the cluster using GitHub authentication

The primary way to log in to the OpenShift cluster is to use your GitHub login. If your GitHub user is a member of the OpenRiskNet 
organistion's [developers team](https://github.com/orgs/OpenRiskNet/teams/developers) then you can log into the cluster using your
GitHub login. This gives you basic access rights, currently including the ability to create your own projects for which you will
be an administrator. 

If you need addtional rights or rights for other projects then these can be granted by a user who has `cluster-admin` role, or `admin`
role for a particular project. We do not grant `cluster-admin` role to GitHub users and restrict this to designated admin users 
accounts.

## To log in to the OpenShift web console

Go to [https://prod.openrisknet.org/]() in your browser.

Choose the `github` option among the `Login with ...` options. This will take you to GitHub to log in (if you are not already logged in).
Enter your GitHub username and password.
If this is the first time you will be asked to confirm that you want to allow the OpenShift console to use you GitHub login. OpenShift
never sees your GitHub credentials.

## To log in to OpenShift using the CLI

Install the `oc` client on your computer. This can be downloaded from [here](https://github.com/openshift/origin/releases).
Choose the appropriate `openshift-origin-client-tools-*` package for your computer. Probably best to install the same version as 
is running on the cluster (currently 3.7.2 but check this in case it's changed) though probably it will do no harm to use a more
recent version.

Alternatively we can provide a SSH login to the bastion machine on the SSC where `oc` is already installed and there is fast
network connection to the cluster, but this is best avoided unless necessary.

Once `oc` is installed do this:
1. log in to the web console using your GitHub account as described above
1. From the user menu in the top right corner of the page select the `Copy Login Command` option
1. Paste the copied text to a terminal window where the `oc` client is present

The copied command will look like this:
```
oc login https://prod.openrisknet.org --token=*******************************************
```

