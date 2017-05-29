This procedure explains how to set up a backup flow for jenkins that uses the ThinBackup plugin to create backups of 
the configuration to the file system and then uploads the newest configuration to a google storage using a service account.

## Google console

* Navigate in the google console to: IAM -> Service Accounts
* Create a service account with no role
* Create key file, store it securely

* Now navigate in the console to: Storage -> Browser
* Create a storage bucket
* Edit bucket permissions, add service account email with write permission

## On the jenkins server terminal

The easiest way to enable upload to google storage is via the gcloud and gsutil tools. This install is a bit heavy 
and there are ways to use just gsutil standalone, but they complicate the auth step a bit, so here is the simpler way via gcloud.
First, install gcloud, as described here: https://cloud.google.com/storage/docs/gsutil_install#deb

Now, authorize gsutil with credentials of the service account (do this as the jenkins shell user):

```
sudo su jenkins
gcloud auth activate-service-account SERVICE-ACCOUNT-EMAIL --key-file PATH-TO-KEYFILE --project GOOGLE-PROJECT-ID
# test uploading a file:
gsutil cp FILENAME gs://STORAGE-BUCKET-ID/FILENAME
```

## Setup the jenkins ThinBackup plugin

Go to the Jenkins web Admin ui, get the ThinBackup plugin. Go the backup settings, disable any build artifacts if enabled (they are big and we 
don't care about them) and set the path to the backup dir. Click the backup button and see if a backup folder gets created there. If so,
enable periodic full backups (e.g. once daily)

## Setup daily zipping and uploading

Get the python script jenkins-backup-upload.py from this git repo folder and put it into the crontab for the jenkins user

```
sudo nano /etc/crontab
# put this in the crontab for daily uploads:
# 15 6 * * * /usr/bin/python PATH-TO-JENKINS-BACKUP-PYTHON-SCRIPT BACKUP-DIR
```
