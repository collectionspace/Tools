Managing iReports
================

11/27/2013, updated 08/31/2015

OVERVIEW
=======

Each CSpace deployment includes several customized reports created using iReport.  Some of these reports are intended to be generated from within CSpace and so need to be installed as documented in the wiki.  Others are run "standalone", meaning that they are executed on a user's local system and access the CSpace database via a JDBC Postgres connector.

Those that are installed in CSpace need to be maintained alongside the CSpace installation itself -- if the system is upgraded, for example, the reports may needed to upgraded and reinstalled as well.  In addition, installed reports use the .jasper binary version of a report (i.e. the "compiled file"), while the standalone reports can be executed via the iReport desktop application using either the source .jrxml file or the .jasper file.

This document documents the best practice for developing, installing, and maintaining iReports for use with CSpace.

IREPORT DEVELOPMENT
===================

Reports are designed and developed in collaboration with museum staff.  Typically, museum staff provide printed and/or digital versions of existing "legacy" reports, or mockups or other specifications for new reports.  The iReport developer then creates a report using the iReport application.  NB: care must be taken to ensure that the iReport version used is compatible with the JasperSoft runtime installed in CSpace, and that fonts, images, and other dependencies in the report exist on the system used to generate the report.

Typically, the developer configures an iReport datasource to point to the development server for the CSpace deployment in question, and identifies appropriate test data (e.g. CSIDs or lists of CSIDs) to use as defaults during the development process. This often entails logging into the development server and creating suitable cases for reporting.

Once developed, the source .jrxml files are checked into the git repository for the institution, under https://github.com/cspace-deployment/Tools/reports, e.g.

    https://github.com/cspace-deployment/Tools/reports/pahma

Thereafter, the source files can be updated and managed in the usual way.

Developing iReports requires:
* creating the iReport
* testing and committing to your fork of the Tools repo for the appropriate institution
* issuing a pull request (e.g "PAHMA-1311: adding jrxml file")

IREPORT DEPLOYMENT: STANDALONE
==============================

For standalone iReports (i.e. using JasperSoft studio on your own computer), no defined procedure is necessary: it is the user's responsibility to ensure that the system is suitably configured for the reports needed.  Configuration required includes

* Sufficient RAM and CPU resources for the version of iReport being run.
* Suitable OS versions
* Installation of the appropriate version of iReport
* Installation of the appropriate JDBC connector for CSpace (typically the Postgres JDBC driver)
* Fonts, graphics, etc. as needed.
* Printer or other output devices suitable for the reporting task

The user then downloads the desired iReport .jrxml files, either via git on the command line or by browsing the git repository via a web browser.

IREPORT DEPLOYMENT: IN CSPACE
=============================

Deploying iReports within CSpace requires (in broad strokes):
* checking out the desired .jrxml file(s) from git
* moving the .jrxml files to the appropriate tomcat directory on the target system.  While this can be accomplished in one step if one has write access to the target directory, it is usually necessary to first stage the file(s) to one's local clone of the Tools repo on the target system, then cp or sudo cp the files to their final destination. (Note: CSpace will compile the .jrxml file when it is first called into a .jasper file)
* If you are replacing an existing report, you'll want to get rid of the existing compiled (.jasper) file: otherwise CSpace will not recompile your new one!
* instructing CSpace about the name and context for the report. This involves a call to the REST API with an XML payload containing this information.  Scripts for "loading" iReports (and performing other maintenance) are provided in the git repository. Note that these need to be configured for each target system. See below for details.

IREPORT ONGOING MAINTENANCE
===========================

The practice below is suggested to aid in ongoing maintenance of iReports.  It is pretty basic, and does not include a real test-based approach -- it merely instructs you on how to deploy reports from GitHub, and presumes you'll test the deployed reports after they are installed.

Having a suite of test cases to use in debugging and QA would help prevent regressions and ensure that the correct results are produced!

The steps are as follows:

```
1. create or accept as JIRA for this work, describing in as much detail as possible what is required.
2. read the code (if the report already exists), determine what to do to implement fix... Or write the report...
3. create clone or fork of Tools repo on your machine ... or just cd to it if you already have one.
4. make sure your local repo is up-to-date.
5. modify file(s) using JasperSoft Studio, or, if you are a wizard, edit the XML directly with your favorite IDE or source code editor.
6. test fix(es) on your local machine (using JasperSoft Studio); yes, you'll need to set up database connections, usually with an SSH tunnel involved.
7. check your edits using 'git diff'
8. add file(s) to commit
9. make commit (referring to relevant JIRAs)
10. push code up to production repo (cspace-deployment) only if you have the necessary write privileges to do so.
11. Otherwise, update your own fork and make a pull request.
12. double check that commit "took" on GitHub. e.g. https://github.com/cspace-deployment/Tools/commit/....
13. update the desired server (dev or prod) with the new .jrxml file as follows:
    a. sign into the desired server: ssh cspace-dev.cspace.berkeley.edu (or own local dev server)
    b. log in as the application owner for the deployment you want to operate: e.g. sudo su - app_pahma
    c. run the deployment script: csdeployreports  (this re-deploys *all* the reports, which will do the trick)
    d. logout: exit
    
    if this report will display in a Django web app (see PAHMA-823 for details of why you have to do this) also do the following:
    
    f. sudo into the webapps server: sudo su - app_webapps
    g. copy the new file(s) from temp to this directory: cd ~/Tools; git pull -v ; cp reports/*/*.jrxml ~/jrxml/

14. if all you are doing is updating an existing report, then you are done. Otherwise, read further below about making a "report record" in CSpace using the helper scripts.
15. test to see the reports work on Prod and Dev. In the case of Prod reports, some of them can be (and should be) tested via the ireports webapp, e.g., https://dev.cspace.berkeley.edu/botgarden_project/ireports/
16. resolve JIRA(s)
17. notify customer of fix
```

Note that this workflow presumes you use git from the command line. If you are using an IDE to do your editing and communicate with GitHub, steps 3-11 of this workflow will differ for you. Adjust accordingly.

Example monologue: install a new report for PAHMA on Production; you can cut and paste these commands

```
# assuming all the changes to .jrxml files are already committed to GitHub...
$
# ssh to Prod
$ ssh cspace-prod.cspace.berkeley.edu
# ... then we become the appropriate CSpace pseudo-user
-sh-4.1$ sudo su - app_pahma
# ... then update the repot. It does not (should not!) hurt to recopy all of them
[app_pahma@cspace-prod-01 ~]$ cd ~/src/cspace-deployment/Tools ; git pull -v ; cd
Fast-forward
 datasources/ucjeps/solrETL-public.sh |    2 +-
 reports/pahma/GroupWithImages.jrxml  |  257 ++++++++++++++++++++++++++++++++++
 2 files changed, 258 insertions(+), 1 deletions(-)
 create mode 100644 reports/pahma/GroupWithImages.jrxml
# ... then we invoke the deployment scripts
[app_pahma@cspace-prod-01 ~]$ csdeployreports
# go back to being ourselves again
-sh-4.1$ exit
# we're done here!
-sh-4.1$ exit
$
```

USEFUL HELPER SCRIPTS
=====================

These helper scripts need environment variables containing the hostnames, logins, and passwords for the target system.  There is a script called set-config.sh which sets these values, and the other scripts check to see that they are set.  Therefore, it is only necessary to modify (and call) the set-config.sh script once for all the other scripts.  You may want to put either an invocation of this script or set the variables in your own login profile.

One can run these from a clone of the Tools repo. There are a couple tricks, as described below:

```
cd Tools/reports/helpers
```

Replace 'tenant' below with an indicator of which tenant deployment you are working with, e.g. 'pahma-prod'

```
cp set-config.sh set-tenant-config.sh
vi set-tenant-config.sh
# update credentials and save
source set-tenant-config.sh
```

(See https://github.com/cspace-deployment/Tools/reports/helpers/README for details.)

The two variables used are:

```
REPORTURL="http://hostname"
REPORTUSER="user@target.cspace.berkeley.edu:password"
```
To list the installed reports (always a good way to start, to make sure you have connectivity and understand the status quo on the server you are working with:

```bash
$ ./list-reports.sh
```

This prints the CSID and report names of the reports installed on the target system.

Note: You can also get a list of reports by making a call directly to the report service API, e.g., 
  http://botgarden.cspace.berkeley.edu/cspace-services/reports/
  
To load a report (i.e. create a CSpace record for the report):

```bash
$ ./load-report.sh full/path/to/reportname.jrxml  "report name" doctype "note"
```

This script checks that the file reportname.jrxml exists, then configures an XML payload and calls the REST API to install the report. "report name" is the value that will appear in the dropdown in UI, and "doctype" is the value of <forDocType>, which specifies the context for the report.  This value can be hard to find. Some examples _may_ be: CollectionObject, Group, Exhibition, but note that some contexts have the tenant identifier included. YMMV!

If you make a boo-boo, or need to replace an existing report record with another, the thing to do is delete the record and make a new one.

```bash
$ ./delete-report.sh reports <CSID>
```

This deletes the report identified by CSID from the CSpace configuration; does *NOT* delete the .jasper file on the server of course! You can find the CSID of a report using list-reports.sh.

Note: You can also delete individual reports using the Firefox plugin, Poster.  The URL will be the full URL for the report service on the host followed by the CSID of the report to delete, e.g., 
  http://botgarden.cspace.berkeley.edu/cspace-services/reports/b3743540-8c99-412f-b851
Enter the credentials; select Delete from the dropdown of Actions; and click the green circular "go" button.

MANUAL RECIPE FOR UPDATING AN iREPORT
=====================================

Here's how to do this stuff by hand, at the command line, rather than using the scripts above. These instructions reference the "legacy" operating environment for CSpace at UCB. They should be viewed as "obsolete, for exemplification only."

EXAMPLE: Revising the UCJEPS Collector Label (Word) report for Groups on the ucjeps-dev server.
ENVIRONMENT: ucjeps-dev is running CollectionSpace 3.3, iReport version __, postgres v. __ on a Red Hat 6(?) Linux VM.

WHAT TO LOOK FOR / WHERE TO LOOK
• In the CollectionSpace web UI, reports appear in the right sidebar of the cataloging or procedure record for which the report was written. On the ucjeps-dev instance, the Collector Label (Word) report is available on the Group record. 
• On the server, the .jrxml and .jasper files the define the report can be found in the /usr/local/share/tomcat/cspace/reports/ directory.
    - ucjepsCollectorLabel_group.jrxml
    - ucjepsCollectorLabel_group.jasper
• In the nuxeo database, reports are stored in reports_common 
    From the nuxeo prompt, run: nuxeo=> select * from reports_common;

TASK SUMMARY

Several tasks are described. 

• If you are updating an existing report, all you need to do is move and delete two files (.jrxml and .jasper. YOU DO NOT NEED TO DELETE THE REPORT'S RECORD IN CSPACE UNLESS YOU NEED TO CHANGE SOMETHING ABOUT THE CONTEXT OF THE REPORT AS USED IN CSPACE -- e.g. which record type it appears with.)

• If you are adding a new report, you'll need to move a file AND create a report record for it.

* If you need to delete a report, technically all you need to do is delete the report record, but cleaning up the files is of course good practices.



Deleting a report:

1. Determine the CSID of the report that you want to replace.
     • https://ucjeps.cspace.berkeley.edu/cspace-services/reports/ (login with ucjeps-dev credentials).
     • Find report by name and copy its CSID

2. Delete the existing report via a call to cspace-services.
     • curl -i -u admin@ucjeps.cspace.berkeley.edu -X DELETE https://ucjeps-dev.cspace.berkeley.edu/cspace-services/reports/{CSID}   (provide user password when asked)
     • Report should disappear from the database.

3. Delete the .jrxml and .jasper files for that report from the server.
     • cd /usr/local/share/tomcat/cspace/reports
     • sudo rm {filename} -- once for each file, or use * at end of partial file name, being sure that the wildcard doesn't match any unintended files. (Use sudo rm ucjepsCollectorLabel_group.j* for removing both the .jrmxl and .jasper files, without touching the files for the _concat version of the report.)

Installing a new report:

1. Securely copy the new .jrxml file to server.
     • from the local machine:
       scp /Users/rjaffe/Desktop/ucjepsCollectorLabel_group.jrxml ucjeps-dev.cspace.berkeley.edu:/usr/local/share/tomcat/cspace/reports/ucjepsCollectorLabel_group.jrxml
     •  In this case, the file I want to copy sits on my desktop.

2. Change ownership of .jrxml file (may or may not be necessary for your deployment):
     • sudo chown tomcat:tomcat ucjepsCollectorLabel_group.jrxml 

3. Change mod of .jrxml file (although this seemed to happen automatically if I chown after initializing and running the report):
     • sudo chmod u-x ucjepsCollectorLabel_group.jrxml
     • sudo chmod g-x ucjepsCollectorLabel_group.jrxml
     • sudo chmod o-x ucjepsCollectorLabel_group.jrxml

4. "Initialize" or "register" this report, i.e. send a request to cspace-services with an .xml payload that provides the name and context for the report and instantiates the report so that CSpace assigns it a CSID.

     • curl -i -u admin@ucjeps.cspace.berkeley.edu -X POST -H "Content-Type: application/xml" https://ucjeps-dev.cspace.berkeley.edu/cspace-services/reports -T /Users/rjaffe/Desktop/ucjepsCollectorLabel_group.xml  
(Note that .xml file is sent from my desktop.)
     • Report should appear in the database.

5. Clear browser cache and run the report from the CSpace UI. 
     • Report should be created and either appear in the browser or be downloaded per browser settings to your local machine.
     • The compiled .jasper file is created automatically.
     
Updating a report (no change in CSpace record):

1. Follow steps 1-3 of Installing a report. The report record as "registered" in CSpace need not change.

