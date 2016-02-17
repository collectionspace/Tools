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
