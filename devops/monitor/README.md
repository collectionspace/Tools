Several scripts useful for monitoring webapps, both Legacy and Django

These scripts all run out of ~/monitor, and currently ~ is app_webapps.

The scripts:

analyze.sh :: analyzes the Django webapp logs, e.g. ~/pahma/logs/logfile*

monitorWebapps.pl :: summarizes usage of Legacy webapps based on Apache logs (at the moment, these
                     are logging activity to the error log. *Sigh*

monitorImageCache.sh :: monitors the size of the imageserver caches (i.e. send email).

topblobs.sh and genlogs.sh are helper scripts to analyze.sh

See below for how to configure these script to run via cron.

NB:

All of these scripts expect to keep persistent, cumulative data in the directory in which they are run,
nominally ~/monitor.

There is one cron job that maintains a list of all the images ever uploaded using the BMU; this is really
just a bash one-liner and there is no code associated with this process

Fuerthermore, since on the managed servers these scripts, running as user app_webapps, cannot access
the Apache logs, they assume that some other cron job will make an extract of those logs available /tmp.

At the moment, I have 2 cron jobs running under my developer account that run nightly to
make these files available in /tmp for user app_webapps.

```bash
01 07-20 * * * cat /var/log/httpd/webapps.cspace.berkeley.edu_443-error_log > /tmp/apache_errors.log
30 00 * * * for t in bampfa botgarden cinefiles pahma ucjeps; do cat /var/log/httpd/${t}.cspace.berkeley.edu_443-access_log | grep -P '(cspace|collectionspace)' > /tmp/${t}.access.log ; done
```

(these may be found in the file in this directory called "crontab.special.user"

To set up on a managed server (very schematic instructions follow!):

```bash
# we should be in the homedir for user app_webapps
cd
# make a directory for monitoring code
mkdir ~/monitor
cd ~/monitor
# copy the scripts (stored in the ucjeps directory at the moment)
cp ~/Tools/devops/monitor/* .
# make some directories for logs, etc.
./mkdirs.sh
# set up cron jobs -- see examples above
crontab -e
```

Here are the monitoring cron jobs running as app_webapps on Prod. They may be found in
crontab.app_webapps in this directory.

```bash
##################################################################################
# monitor webapp use
##################################################################################
5 07-20 * * * cat /tmp/apache_errors.log | grep '::' | grep ' end ' | perl -pe 's/^.*?\[... (.*?)\].*client (.*?)\]/\1\t\2\t/;s/ *:: */\t/g;s/, refer.*webapp=/\t/;' > ~/monitor/currappuse.csv ; cat ~/monitor/currappuse.csv ~/monitor/webappuse.csv | sort -u > /tmp/tmp2 ; mv /tmp/tmp2 ~/monitor/webappuse.csv ; perl ~/monitor/monitorWebapps.pl ~/monitor/webappuse.csv > /var/www/static/webappuse.html
5 04 * * * cd ~/monitor ; ./analyze.sh
##################################################################################
# monitor imageserver caches
##################################################################################
0 4 * * * cd /home/app_webapps/monitor ; for t in bampfa botgarden cinefiles pahma ucjeps; do  ./monitorImageCache.sh ~/cache/$t  > report.txt 2>&1 ; cat report.txt | mail -s "image cache status" -- jblowe@berkeley.edu ; python checkCache.py ~/cache/$t >> $t.imagecache.log ; done
##################################################################################
# keep a set of the BMU log files
##################################################################################
5 6 * * *  for t in bampfa botgarden cinefiles pahma ucjeps; do  cp -p /tmp/image_upload_cache_${t}/*.csv  /home/app_webapps/monitor/image_upload_cache_${t}/  ; cp -p /tmp/image_upload_cache_${t}/*.trace.log  /home/app_webapps/monitor/image_upload_cache_${t}/ ; done
##################################################################################
# monitor image caches
##################################################################################
0 4 * * * cd ~ ; ./monitorImageCache.sh "/tmp/image_cache/"  > report.txt 2>&1 ; cat report.txt | mail -s "ucjeps cache status" -- jblowe@berkeley.edu
```

Now pretty much defunct, checkCache.py writes a single line with 5 values. It counts files, directories, and total size in bytes in the specified
directory.  Useful for gathering a historical record on the the contents of a directory like a cache.

It can also be run via cron using something like the following:

```bash
0 5 * * * cd ~ ; python checkCache.py /images/cache/ >> imagecache.log

The results look like:

[jblowe@pahma-dev ~]$ tail imagecache.log
2015-02-23 05:00:01 files 49376, dirs 35822, size 42801975792
2015-02-24 05:00:01 files 50088, dirs 36137, size 42848851839
2015-02-25 05:00:01 files 50100, dirs 36142, size 42858752500
2015-02-26 05:00:01 files 50206, dirs 36185, size 42894830120
```

