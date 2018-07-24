# Postgres Backup and Recovery (OpenShift)
This recipe describes a mechanism that can be employed to automate the
backup and recovery of a PostgreSQL server in an OpenShift cluster.
Even if you have a resilient High-Availability server an independent
backup is always useful.

The backup and recovery recipe described here relies on the actions of the
[pg_dumpall] utility, a PostgreSQL utility for writing out ("dumping")
all databases of a cluster into one SQL script file. Recovering from the output
of `pg_dumpall` is simply a matter of using the `psql` command-line utility.

This recipe provides links to a pair of Python modules, Docker images
and OpenShift templates in a GitHib repository that provide you with a
simple and configurable wrapper around the backup and recovery process.

>   Source code, Dockerfiles and templates can be found in the
    [Informatics Matters] [GitHub] repository.

## The backup image
>   You'll find comprehensive documentation in the
    `backup.py` Python module ([backup.py]).

This module is responsible for invoking `pg_dumpall` but exposes the ability
to collect and manage backups according to the number of backups that you want
to keep based on four types of backup strategy: _hourly_, _daily_, _weekly_ and
_monthly_.

You could: -
 
-   Keep _hourly_ backups for 24 hours
-   _Daily_ backups for a week
-   _Weekly_ backups for a month
-   _Monthly_ backups for 3 years  

The is controlled by four environment variables, described in the [backup.py]
module: -

-   `BACKUP_TYPE`
-   `BACKUP_COUNT`
-   `BACKUP_PRIOR_TYPE`
-   `BACKUP_PRIOR_COUNT`

## The backup OpenShift image and template
The backup can work independently of OpenShift (it is just a Docker image
after all) but it's designed to run within an OpenShift environment as
a [CronJob] - a special object that, like cron, is executed by the OpenShift
scheduler using a cron-like execution definition.

An example [backup.yaml] that illustrates a typical _hourly_, _daily_,
_weekly_ and _monthly_ strategy is available in the GitHib repository.

The backup image writes backups to the `/backup` directory in the container
and this must be formed from an external volume that is mounted. The
backup will detect the lack of volume and generate a suitable error. The
template examples illustrate the use of a volume.

>   You will need superuser access to the postgres server for the backup and
    recovery to work and the module exposes environment variables to provide
    the user (`PGUSER`), password (`PGADMINPASS`) and host (`PGHOST`).
    So the backup and recovery can work against any server, anywhere.

-   If you just want to create hourly backups at 7-minutes past each hour
    for 24 hours you can do that.

    Define just one **CronJob**, set `BACKUP_TYPE` value to `hourly`,
    `BACKUP_COUNT` value to `24` and `schedule: '7 * * * *'`
      
-   If you want to collect 4-hourly backups for 6 days, you can do that.

    Define just one **CronJob**, set `BACKUP_TYPE` value to `hourly`,
    `BACKUP_COUNT` value to `36` (there are 36 4-hour periods in 6 days)
    and `schedule: '7 */4 * * *`.

>   The [schedule] definition is essentially a copy of the cron definition
    where the fields represent _minute_, _hour_, _day of month_, _month_ and
    _day of week_.

>   It is important to remember that it is only the _hourly_ backup type
    that creates new backups. The _daily_, _weekly_ and _monthly_ backups
    simply copy a backup from the _prior_ type. You must therefore have one
    _hourly_ definition, even if you are just collecting backups once a day.
    And, as a consequence, it is only the _hourly_ job that needs to know
    the postgres host and its credentials.

>   The backup templates have been tested with OpenShift 3.7, where
    the CronJob `apiVersion` is **batch/v2alpha1**. Until the CronJOb becomes
    a formal part of the OpenShift release this may vary depending on your
    OpenShift version.
 
## The recovery image and template
The recovery image (based on the [recovery.py] module) can be used to simplify
the restoration of data from one of the backup images.

Again, there is comprehensive documentation in the `recovery.py` module, which
won't be repeated here.

One of the problems we needed to solve was to _streamline_ both the backup
and recovery process and the recovery module is good at satisfying this need.
You simply mount the same backup volume, specify the postgres host
and then set `FROM_BACKUP` environment variable to `latest`.

You can use the recovery image to simply list all the backups
(set `FROM_BACKUP` to `none`) or a specific backup using its date and time
(i.e. set `FROM_BACKUP` to the date and time of an existing backup,
like `2018-07-23T11:46:33Z`).

The recovery image normally runs as an OpenShift [Job] and an example can be
found in the GitHib projects's [recovery.yaml] file.

>   The backup image log displays the backups available for its type
    (_hourly_, _daily_, _weekly_ or _monthly_) and you can see all backups
    with the recovery image (by setting `FROM_BACKUP` to `none`).
    
>   Before running the recovery you might want to stop your backup as it may
    change the latest backup or remove the one you are recovering from.

**Importantly** your recovery database must have the same superuser credentials
used for the backup. If you backed up a database with an admin of
`postgres/password789` then the destination server must also use these
credentials.

## The backup volume
You will need a volume and a **Persistent Volume Claim** (`PVC`) for both the
backup and recovery containers. Importantly the volume must be `ReadWriteMany`.
An example `PVC` template can be found on the GitHub project as [pvc.yaml].

---

[backup.py]: https://github.com/InformaticsMatters/bandr/blob/master/postgresql-backup/backup.py
[backup.yaml]: https://github.com/InformaticsMatters/bandr/blob/master/postgresql-backup/backup.yaml
[recovery.py]: https://github.com/InformaticsMatters/bandr/blob/master/postgresql-recovery/recovery.py
[recovery.yaml]: https://github.com/InformaticsMatters/bandr/blob/master/postgresql-recovery/recovery.yaml 
[pvc.yaml]: https://github.com/InformaticsMatters/bandr/blob/master/postgresql-backup/pvc.yaml

[cronjob]: https://docs.openshift.com/container-platform/3.7/dev_guide/cron_jobs.html
[job]: https://docs.openshift.com/container-platform/3.7/dev_guide/jobs.html
[github]: https://github.com/InformaticsMatters/bandr
[informatics matters]: https://www.informaticsmatters.com
[ps_dumpall]: https://www.postgresql.org/docs/9.5/static/app-pg-dumpall.html
[schedule]: https://docs.openshift.com/container-platform/3.7/dev_guide/cron_jobs.html
