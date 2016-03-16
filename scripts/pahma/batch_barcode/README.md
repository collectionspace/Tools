This is the "batch_barcode" facility.

It processes Tricoder files uploaded via the Tricoder File Upload webapp, doing the following:

* Extensive checking of file content: handlers, locations, objectnumbers all get verified
* LMI records created
* 2 Relation records for each LMI record

It is set to run every hour during the week from 9-6.  Here's the crontab entry for it on cspace-dev 

```
##################################################################################
# run the tricoder upload job 10 mins after the hour from 9am to 6pm during the week
##################################################################################
10 9-18 * * 1-5 /home/app_webapps/batch_barcode/import_barcode_typeR.sh &> /home/app_webapps/batch_barcode/log/all_barcode_typeR.msg
```
A few operational details

The system is configured in setBarcodeEnv.sh. A CSpace account with appropriate permissions is needed, 
as is a connect string to make pSQL queries

The system sends email after each run with the results.

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
