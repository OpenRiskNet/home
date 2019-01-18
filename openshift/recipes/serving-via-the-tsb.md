# Serving applications from the OpenShift Template Service Broker (TSB)

Deploying application from templates should be a familiar process but the
act of installing applications can be streamlined and moved off the
command-line by employing the OpenShift Template Service Broker ([TSB]).

The TSB provides a service catalogue of *built-in* applications but
it can also be used as to serve-up anything for which a template has been
written.

>   Before continuing make sure you're familiar with OpenShift [templates]

>   As a good working reference of a TSB-compliant template you can refer to
    the **BridgeDB** template (`BridgeDb-Version 2/bridgedb.yaml`).

## Preparing your template

If your application is already deployed using a template you're almost
ready. You just need to add some annotations in the template's metadata
in order to *beautify* the app's presentation in the TSB.
These annotations are described in the **Description** section of the
OpenShift [templates] documentation.

### Metadata

Add some key `metadata` annotations, which should be: -

-   `description`
-   `openshift.io/display-name`
-   `openshift.io/provider-display-name`
-   `openshift.io/documentation-url`
-   `openshift.io/support-url`
-   `iconClass` (see below)

### Message

Add a template `message` property to provide post-installation instructions.
Something useful here might be instructions on removing the application.

### Icon

You can display an icon for your application by selecting a suitable icon from
a basic set that are [built-in] or from those available from the 4.7 version
of [Font Awesome].

>   Adding icons using CSS stylesheets is currently
    beyond the scope of this note.

## Installing an application template

An **OpenRiskNet Applications** namespace should be available on the production
and development servers, accessible using the **developer** account.
We deploy our application templates here.

With a developer login for the appropriate server install your template
with the following oc command: -
 
    oc create -f <template> -n openrisknet-applications

>   If you are greeted with the error **User "...." cannot create templates
    in the namespace "openrisknet-applications"** then you have not be
    authorised to **Edit** the openrisknet-applications project. Contact
    a system administrator who should be able to enable your access
    with the command
    `oc adm policy add-role-to-user edit <you> -n openrisknet-applications`

>   Note - if you make modifications to your template you will need to remove
    the old template from the TSB and install the new one. The TSB does
    not know where your template came from so the installed template is
    a static copy of a template. See the *Removing application templates*
    section below. 
   
## Installing an application from a template

With your template installed, from a suitable destination *project* you will
be able to install the application using the project's *Add to Project* option
(usually found in the top-right of you r project window). From there
navigate to the required application application using
*Select from Project -> OpenRiskNet Applications*.

You should inspect and modify any variables accordingly and follow
the pop-up wizard's instructions.

## Removing application templates

From the command-line you can remove a pre-installed application with
an oc command: -

    oc delete template/<template> -n openrisknet-applications
    
>   This removes the application's template, not the applications
    installed from it.
    
## Best practices for TSB-compliant templates

1.  Expose suitable `parameters`, those template values that an *end-user*
    might reasonably expect to adjust
1.  Use the `message` property of the template, at least to provide the user
    with post-installation instructions and (ideally) application
    removal instructions
1.  Add succinct and helpful descriptions to **all** of your template's
    `parameters`.
1.  Try to deploy to a an **exclusive project** (namespace), one where
    only you application resides. You can then remove the application by
    simply removing the project.


[built-in]: https://rawgit.com/openshift/openshift-logos-icon/master/demo.html
[font awesome]: https://fontawesome.com/v4.7.0/icons/
[templates]: https://docs.openshift.com/container-platform/3.7/dev_guide/templates.html#dev-guide-templates
[tsb]: https://docs.openshift.com/container-platform/3.7/architecture/service_catalog/template_service_broker.html
