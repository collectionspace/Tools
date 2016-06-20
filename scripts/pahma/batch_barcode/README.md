This is the "batch_barcode" facility.

It processes Tricoder files uploaded via the Tricoder File Upload webapp, doing the following:

* Extensive checking of file content: handlers, locations, objectnumbers all get verified
* LMI records created
* 2 Relation records for each LMI record

It is set to run every hour during the week from 9-6.  Here's the crontab entry for it on cspace-dev 

```
##################################################################################
# run the tricoder upload job 3 mins after the hour from 9am to 6pm during the week
##################################################################################
3 9-18 * * 1-5 /home/app_webapps/batch_barcode/import_barcode_typeR.sh &> /home/app_webapps/batch_barcode/log/all_barcode_typeR.msg
```
A few operational details

The system is configured in setBarcodeEnv.sh. A CSpace account with appropriate permissions is needed, 
as is a connect string to make pSQL queries

The system sends email after each run with the results.

General workflow:
* PAHMA staff upload barcode files to a directory; contents get copied to CSpace server
* Cron job runs M-F, 9-6, at 3 minutes after the hour, executing /home/app_webapps/batch_barcode/import_barcode_typeR.sh
* The script looks for files (can be multiple) and processes them one at a time.  Process splits each file into up to three record types (M=5-field, C=6-field, R=MvCrate), checks the input, processes the three kinds using Talend jobs, uses sed to do final cleanups (schema2 to schema) resulting in *.fixed.xml files, imports the resulting XML using curl, and does some cleanup.  
* The script works on one file at a time even though PAHMA staff can upload multiple files per hour.  There is therefore the possibility that files from one hour will not have been processed by the time the next cron job kicks off.  This can be a problem.  We ask that each file have no more than 5K records to create overall (including relationship records), and that can be a challenge.  If each batch of 1000 records can take 5 minutes, then the system has capacity for 12K records per hour.  If that is exceeded, then failures can be expected.  When the system is busy, it can take more than 5 minutes to load 1000 records.  The curl job is  allowed to retry two times.

Log files:
* Console output of shell job called by cron output to verbose file, /home/app_webapps/batch_barcode/log/all_barcode_typeR.msg
* Each time the cron job finds and processes one or more uploaded files, it will email per-file log messages to pahma-tricoder and us
* Those per-file log messages are also stored in /home/app_webapps/batch_barcode/log in files like Barcode_log.20160617-0903.  Sometimes the email message might not come through (at least I think I've experienced that once.)
* A more verbose daily log is kept in the same directory in files like Barcode_log.20160617.  This can be a challenge to read because different steps in the shell script can be executing at the same time.  If a cron job fires off before the previous run is complete, this confusion will be confounded.
* In some cases, the email message and per-file log did not produce reliable output.  This probably seems to occur when jobs are colliding with each other.  In those cases, you might need to look at the more verbose log to see what the result was.

Locations of files after runs:
* Original data files: /home/app_webapps/batch_barcode/processed
* Rejected files: /home/app_webapps/batch_barcode/bad_barcode
* /home/app_webapps/batch_barcode/log
* XML files and curl output (gzip'd): /home/app_webapps/batch_barcode/temp/location/done and /home/app_webapps/batch_barcode/temp/relation/done

In the end, you might just want to see which files loaded no records (look for 0 counts), and then reload them using reloadxml.sh

## A few notes on how to deploy from GitHub
```
# get the code
cd ~/Tools/
git pull -v
# the "working directory" is ~app_webbaps home dir
# put the code there.
cp -r scripts/pahma/batch_barcode/ ~/batch_barcode
# edit the config file (passwords, etc.)
vi setBarcodeEnv.sh
# actually you probably won't be editing the following file much, except
# when you need to add new handlers.
vi LocHandlers.txt
#
# get rid of the readmes: GitHub needs them, but otherwise they are just clutter
rm input/README.md
rm bad_barcode/README.md
rm processed/README.md
rm holding/README.md
# selinux: make it possible for the webapp to write files to the input dir
chcon -t httpd_user_content_t batch_barcode/input/
#
# let's try it out!
#
# copy a test file we have created to the input dir.
# nb: the file should be a valid file (name, etc.) unless of course we are testing failure modes
# nb: file has to have today's date or it will be ignored.
cp ~/barcode.TRIDATA_2015-MM-DD_Number6_test.test.DAT  input/barcode.TRIDATA_2065-05-07_Number6_test.test.DAT
# invoke the batch script (see crontab for current version)
/home/app_webapps/batch_barcode/import_barcode_typeR.sh &> /home/app_webapps/batch_barcode/log/all_barcode_typeR.msg &
# wait...wait...wait
#
# did it work? if so, look in processed. if not, look in bad_barcode
ls processed/
ls bad_barcode/
```
