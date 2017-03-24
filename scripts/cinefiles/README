CINEFILES QUALITY CONTROL (QC) SUITE

This QC suite check files (either in directories or in CSpace) on the assumption that they are
properly constructed TIFF images as used in cinefiles.

See BAMPFA-113 for the requirements, etc. of this suite.

This script operates in one of two modes:

* 'db' mode, where the blob list is created from a supplied date range and the blobs are
  expected in the local filesystem in CSpace. (this is the mode currently in use.)

* 'dir' mode, where the user supplies a directory containing files to check. (this would be used for making
  ad hoc checks of files)

To invoke:

python checkBlobs.py db  config-file-no-extension start-date end-date report.csv
python checkBlobs.py dir directory report.csv

e.g.

python checkBlobs.py db  cinefilesProd '2014-02-06 17:55:31'  '2014-02-06 18:16:53' report.csv
python checkBlobs.py dir /ftp/dir report.csv

where:

datasource = db | dir (if db, get list from database, if dir, use supplied directory)
config-file-no-extension = configuration file for CSpace server, in "webapp format" (i.e. .cfg file)
start-date, end-date = two timestamps, can be just dates (times not required)
directory = full path to directory containing image files.

the most recent report:

nohup time python checkBlobs.py db cinefilesProd '2010-01-01' '2014-02-25' report2010on.csv &

The script takes about 15 minutes to produce a report for all 139K images in cinefiles as of this date.

The shell script monthly.sh does the following:
 - produces a report on images updated in CSpace during the the previous month (used updatedAt). 
   The report is called image_qc_report-yyy-mm.csv
 - extracts a list of the images that failed the QC checks, named image_qc_report-yyy-mm.problems.csv
 - compresses the monthly report, and emails both documents to the email address specified in the first argument.
 - invoke as: ./monthly.sh recipient-list@berkeley.edu

Notes:

A directory called tiffs/ contains 3 test files is provided. 
To use it, try: python checkBlobs.py dir tiffs test.csv

INSTALLATION NOTES

(these notes pertain to installation on managed servers, specifically, cspace-prod.cspace.berkeley.edu

This "suite" is installed at cinefiles.cspace.berkeley.edu:/home/app_cinefiles/bin/qc

The monthly script runs there with the following cron spec:

00 03 1 * * /home/developers/qc/monthly.sh cinefiles_reports@lists.berkeley.edu

i.e. run at 3AM on the first of each month, email to cinefiles_reports@lists.berkeley.edu

# copy the code from the Tools repo... (not shown here)
cp -r /tmp/cinefiles/ bin/qc

# navigate to the dir where it will run and set it up.
# ssh to cspace-prod...
sudo su - app_cinefiles
cd bin/qc
# set up virtual env
mkdir -p venv
virtualenv --distribute venv/
source venv/bin/activate
# install dependencies
pip install pillow
pip install psycopg2

# configure db access
cp cinefilesProdExample.cfg cinefilesProd.cfg
vi cinefilesProd.cfg
# test it out.
./monthly.sh jblowe@berkeley.edu
# set up cron job
[app_cinefiles@cspace-prod-01 ~]$ crontab -l
00 03 1 * * /home/app_cinefiles/bin/qc/monthly.sh cinefiles_reports@lists.berkeley.edu


