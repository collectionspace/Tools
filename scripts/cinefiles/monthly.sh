set -o verbose
# note the assumptions made by this script:
# - it will run in /home/developers/qc
# - it will run at the beginning of a month and report on the previous month
# - monthly reports will be retained forever..this script does not groom them
# - config file cinefilesProd.cfg exists with the needed paramaters.
#
cd /home/developers/qc
rdate=`date --date="last month" +%Y-%m`
REPORT=image_qc_report-${rdate}
time python checkBlobs.py db cinefilesProd `date --date="last month" +%Y-%m-01` `date --date="this month" +%Y-%m-01` $REPORT.csv
perl -ne '@x = split /\t/; print if $x[1] eq "False"; ' $REPORT.csv > bad.temp
head -1 $REPORT.csv | cat - bad.temp | perl -pe 's/\r//g' > $REPORT.problems.csv
rm bad.temp
all=`wc -l $REPORT.csv | cut -f1 -d" "`
bad=`wc -l $REPORT.problems.csv | cut -f1 -d" "`
all=$((all-1))
bad=$((bad-1))
echo "bad: $bad :: all: $all"
rm $REPORT.csv.gz
gzip $REPORT.csv
echo "Report for the month starting $rdate: $all images, $bad problems, see attached." | mail -a $REPORT.problems.csv -a $REPORT.csv.gz -s "image qc for $rdate: $all images, $bad problems" -- $1
