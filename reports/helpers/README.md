Scripts to help with maintaining iReports on CSpace servers.
======================================

these shell scripts have been tested at UCB on IS&T RHEL Linux servers.

they help you add, delete, enumerate, and configure iReport files.
they depend on the user setting two environment variables specifying
the server and credentials they wish to target.

to target different servers, simply make different config files ("set-config-xxx.sh")
and source them as needed.

using this technique, it is possible to update any CSpace server
you have the credentials for from one place.

## Some Important Caveats

1. the scripts attempt to record activity in a log file.
   this is easily defeated if you modify or update reports
   by other means (manually, or from another server)

2. The scripts expect to have environment variables set
   containing needed parameters. These can be set either
   by hand or (better) by creating a copy of the
   'template' script ("set-config-default.sh") for each
   cspace server you expect to work with, and
   sourcing that script before invoking any others.

3. It is probably wise to use one of the "non-updating"
   scripts first (e.g. list-reports.sh) to check to see if
   your setup is correct.

## THE SCRIPTS

* set-config-default.sh  ::  basic environment var setting script
* load-report.sh report  "report name" "forDocType" "note":: create a report record in CSpace server
* delete-report.sh report-csid  ::  deletes report having specified csid (deletes config only!)
* list-reports.sh > reports.csv  :: lists the reports installed
* list-report-details.sh report-csid  :: xml payload showing details of installed report
* delete-all-reports.sh reports.csv :: deletes all the reports listed in reports.csv
* delete-report.sh report-csid  :: delete a single report record
* fetch-report.sh report-csid context-csid doctype :: fetches a results of a report from the server

EXAMPLES

The following script fetches a PDF report; it takes the csid of the report and the csid of cspace context element (e.g group csid, object csid, etc. depending on report and context).

```bash
$ ./fetch-report.sh f45de201-3429-4d67-a1b2 ebf5f72f-65ab-499f-ac47-4fa9b720a6d3 CollectionObject > groupReport.pdf
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  209k    0  209k  125   250  25899     30  0:00:08  0:00:08 --:--:-- 50492

$ ls -ltr | tail -1
-rw-r--r--  1 jblowe  staff  214744 Aug 18 13:24 groupReport.pdf
```

Script to set environment variables. This script must be customized for the systems you are using, and ```source```'d to set the needed values.

```bash
$ cat set-config-default.sh 
#!/bin/bash
#
export REPORTURL="http://xxx.cspace.berkeley.edu:8180"
export REPORTUSER="xxx@xxx.cspace.berkeley.edu:xxx"
echo
echo ">>>>> Environment variables set:"
echo REPORTURL  $REPORTURL
echo REPORTUSER $REPORTUSER
echo

# copy the default config file.
$ cp set-config-default.sh set-pahma-dev.sh

# edit it so that it has the values for the system you want to work with.
$ vi set-pahma-dev.sh 

# source it to set the environment variables
$ source set-pahma-prod.sh 

>>>>> Environment variables set:
REPORTURL pahma.cspace.berkeley.edu
REPORTUSER xxxx@pahma.cspace.berkeley.edu:xxxx

# now go to town!

# load and configure report (assumes you have or will install a file zzz.jrxml on the server)
$ ./load-report.sh zzz "example object report" CollectionObject ""

# put the .jrxml file where it belongs (use this command when you have modified the report)
ssh my.server
cd Tools
cp zzz.jrxml /usr/local/share/apache-tomcat-6.0.33/cspace/reports/

# make a list of installed reports
$ ./list-reports.sh > listofreports.csv

$ cat listofreports.csv
74c64b69-40c6-4f36-9638	Group Report with sites and locations
f45de201-3429-4d67-a1b2	Basic Object Report
c82b4c85-88ac-4b20-90d1	Basic Group Report

# delete a report (e.g. the Basic Group Report above)
./delete-report.sh c82b4c85-88ac-4b20-90d1
```
