#!/bin/bash -xv

# 12/11/2013 modify for production ... change UPLOAD_PATH, ROOT_PATH (cd)
#
# 10/18/2013 temporarily set UPLOAD_PATH (checking for scanned file) to
#            the "/tmp/tricoder_typeR" directory instead of my home directory)
#
# 10/3/2013 new barcode file type "R" (move crate) have 5 fields:
#            Type, "Handler", "Timestamp", "Crate", "New location"
#    Using "checkinput_mvCrate_typeR.sh" to check handler/crate/loc 
#    to make sure they exists in CSpace.
#
# As before, this allows multiple runs at the same time (close together) ---
#   1. add Talend context var "infile_min" which is the "TIME" in this script
#      it is passed to Talend to form the input filename
#      "/tmp/ProcessMvCrate_"+TalendDate.getDate("CCYY-MM-DD")+"-"+context.infile_min+".barcode"
#      and output filenames (all appending date w/ the "-"+context.infile_min)
#   2. The DATE-TIME is also passed to the "checkinput_mvCrate_typeR.sh" as the 3rd
#      argument, so the intermediate files used for checking are distinguishable 
#      among the runs
#   3. The DATE-TIME is also passed to "talendinput.sh" so it can generate
#      the tab-delimited file with the date/time stamp.
#
# 2/4/2013 Migration to CSpace 3.2 ---
#   + all Talend job now creates XML w/ schema0 (collectionspace_core) that
#     contains the "uri" & "refName" of the procedures (movement & relation)
#   + Talend job for relations also fills the XML w/ subjectUri/objectUri
#     as well as subjectRefName/objectRefName
#   + because of the added "schema0", this batch need to run "sed" to change to "schema"

# set environment variables for this run
source ~/batch_barcode/setBarcodeEnv.sh
+ source /home/app_webapps/batch_barcode/setBarcodeEnv.sh

#set verbose

# target server
export URL="https://pahma-dev.cspace.berkeley.edu/cspace-services/imports"
++ export URL=https://pahma-dev.cspace.berkeley.edu/cspace-services/imports
++ URL=https://pahma-dev.cspace.berkeley.edu/cspace-services/imports
export USER="import@pahma.cspace.berkeley.edu:lash428!puck"
++ export 'USER=import@pahma.cspace.berkeley.edu:lash428!puck'
++ USER='import@pahma.cspace.berkeley.edu:lash428!puck'
export CONTENT_TYPE="Content-Type: application/xml"
++ export 'CONTENT_TYPE=Content-Type: application/xml'
++ CONTENT_TYPE='Content-Type: application/xml'

# password comes from .pgpass
export CONNECTSTRING="host=dba-postgres-dev-32.ist.berkeley.edu port=5107 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma "
++ export 'CONNECTSTRING=host=dba-postgres-dev-32.ist.berkeley.edu port=5107 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma '
++ CONNECTSTRING='host=dba-postgres-dev-32.ist.berkeley.edu port=5107 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma '

# setup for email
export SUBJECT="Importing barcode LMI (C/M/R types)"
++ export 'SUBJECT=Importing barcode LMI (C/M/R types)'
++ SUBJECT='Importing barcode LMI (C/M/R types)'
export EMAIL="jblowe@berkeley.edu"
++ export EMAIL=jblowe@berkeley.edu
++ EMAIL=jblowe@berkeley.edu

export ROOT_PATH=/home/app_webapps/batch_barcode
++ export ROOT_PATH=/home/app_webapps/batch_barcode
++ ROOT_PATH=/home/app_webapps/batch_barcode
export UPLOAD_PATH=${ROOT_PATH}/input
++ export UPLOAD_PATH=/home/app_webapps/batch_barcode/input
++ UPLOAD_PATH=/home/app_webapps/batch_barcode/input
#EMAIL3="pahma-tricoder@lists.berkeley.edu"
# UPLOAD_PATH=/tmp/tricoder_typeR


m=`date '+%m'`  # init to today's month/day/year
date '+%m'
++ date +%m
+ m=09
d=`date '+%d'`
date '+%d'
++ date +%d
+ d=16
y=`date '+%Y'`
date '+%Y'
++ date +%Y
+ y=2015
DATE=${y}-${m}-${d}
+ DATE=2015-09-16
# TIME=`date +%k%M`        # 24-hr format as single digit string
TIME=`date +%H%M`        # this will keep leading zero on the hour
date +%H%M
++ date +%H%M
+ TIME=1402


# PS1 (the prompt variable) is set and $- includes i if bash is interactive, allowing a 
# shell script or a startup file to test this state.
# test using if [ "$PS1" ] reported "interactive" in "cron" job & on command-line
# test using if [ -z "$PS1" ] reported "non-interactive" in "cron" job
#            but also "non-interactive" even on the command-line
# test using if  tty -s , report "non-interactive" from cron, and "interactive" on command-line
# if [ -z "$PS1" ]; then
#    echo "testing PS1: non-interactive"
#    _interactive=0
# else
#    echo "testing PS1: interactive"
#    _interactive=1
# fi

if  tty -s ; then
   echo "testing tty: interactive"
   _interactive=1
else
   echo "testing tty: non-interactive"
   _interactive=0
fi
+ tty -s
+ echo 'testing tty: non-interactive'
testing tty: non-interactive
+ _interactive=0
# echo "interactive = $_interactive"

# ELEMENT_LOG records what's going on in the run of "checkinput_5fld.sh" & "checkinput_6fld.sh"
# If error condition occurred, this should be mailed to the designated email
ELEMENT_LOG=${ROOT_PATH}/log/Barcode_log.$y$m$d-${TIME}
+ ELEMENT_LOG=/home/app_webapps/batch_barcode/log/Barcode_log.20150916-1402

LOGFILE=${ROOT_PATH}/log/Barcode_log.$y$m$d
+ LOGFILE=/home/app_webapps/batch_barcode/log/Barcode_log.20150916
CUMLOG=${ROOT_PATH}/log/ALL_Barcode_LOG
+ CUMLOG=/home/app_webapps/batch_barcode/log/ALL_Barcode_LOG
TMPLOG=/tmp/$$
+ TMPLOG=/tmp/5170

echo "$DATE $TIME" | tee -a $LOGFILE $TMPLOG
+ echo '2015-09-16 1402'
+ tee -a /home/app_webapps/batch_barcode/log/Barcode_log.20150916 /tmp/5170
2015-09-16 1402
echo "Processing new barcode files" |tee -a $LOGFILE $TMPLOG
+ echo 'Processing new barcode files'
+ tee -a /home/app_webapps/batch_barcode/log/Barcode_log.20150916 /tmp/5170
Processing new barcode files

# find number of files matching the barcode file pattern
files=$(ls ${UPLOAD_PATH}/barcode.TRIDATA_${DATE}_*.DAT 2> /dev/null | wc -l)
++ ls /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT
+ files=1
echo "number of files to process: $files"
+ echo 'number of files to process: 1'
number of files to process: 1
if [ "$files" == "0" ]; then
    echo "No barcode files to process ..." |tee -a $LOGFILE $TMPLOG
    # Probably don't need email if there is no file to process?
    # /bin/mail -s "${SUBJECT}" "${EMAIL}" < ${TMPLOG}
    # /bin/mail -s "${SUBJECT}" "${EMAIL2}" < ${TMPLOG}
    exit 0
fi
+ '[' 1 == 0 ']'

# Processing files according to upload time (earlier one on the top (ls -ltr))
echo "$DATE $TIME --- Processing the following file(s):" > ${ELEMENT_LOG}
+ echo '2015-09-16 1402 --- Processing the following file(s):'
ls -ltr ${UPLOAD_PATH}/barcode.TRIDATA_${DATE}*.DAT |sed -e 's/^.*apache [ 0-9][ 0-9]* //' | sed -e 's/\/home\/developers\/barcode\///' | tee -a ${ELEMENT_LOG}
+ ls -ltr /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT
+ tee -a /home/app_webapps/batch_barcode/log/Barcode_log.20150916-1402
+ sed -e 's/^.*apache [ 0-9][ 0-9]* //'
+ sed -e 's/\/home\/developers\/barcode\///'
-rw-r--r--. 1 app_webapps app_webapps 5457 Sep 16 11:49 /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT
BARCODE_FILES=`ls -ltr ${UPLOAD_PATH}/barcode.TRIDATA_${DATE}*.DAT | sed -e 's/^.* //' `
ls -ltr ${UPLOAD_PATH}/barcode.TRIDATA_${DATE}*.DAT | sed -e 's/^.* //' 
++ ls -ltr /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT
+ BARCODE_FILES=/home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT

# ---------------- PROCESS ONE BARCODE FILE AT A TIME -----------------
for SINGLEFL in ${BARCODE_FILES}
do
    NOCRATE=0
    ERRCODE=0
    gotit=0
    echo ""  | tee -a ${ELEMENT_LOG}
    echo "----- STARTING FILE $SINGLEFL -----"  | tee -a ${ELEMENT_LOG}
    # It's crucial to keep the timered-filename upto the seconds
    TIME=`date +%H%M%S`        # %H will keep leading zero on the hour

    wc -l $SINGLEFL | tee -a $LOGFILE $TMPLOG
    grep '^"M",' $SINGLEFL | sort | uniq > /tmp/Process5_${DATE}-${TIME}.barcode
    grep '^"C",' $SINGLEFL | sort | uniq > /tmp/Process6_${DATE}-${TIME}.barcode
    grep '^"R",' $SINGLEFL | sort | uniq > /tmp/ProcessMvCrate_${DATE}-${TIME}.barcode

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # examine "handler", "museum number", "location" in scanned file w/ 5 fields & 6 fields
    # "$?" is the exit code from previous script (the one immediate before calling $?)
    # note: passing {$DATE}-${TIME} as the 3rd arg for creating time-embedded 
    #       tab-delimited file for Talend jobs later
    if [ -s /tmp/Process5_${DATE}-${TIME}.barcode ]; then
        ${ROOT_PATH}/checkinput_5fld.sh /tmp/Process5_${DATE}-${TIME}.barcode ${ELEMENT_LOG} ${DATE}-${TIME}
        ERRCODE=`expr $ERRCODE + $?`
    fi
    if [ -s /tmp/Process6_${DATE}-${TIME}.barcode ]; then
        ${ROOT_PATH}/checkinput_6fld.sh /tmp/Process6_${DATE}-${TIME}.barcode ${ELEMENT_LOG} ${DATE}-${TIME}
        ERRCODE=`expr $ERRCODE + $?`
    else
         NOCRATE=1
    fi
    if [ -s /tmp/ProcessMvCrate_${DATE}-${TIME}.barcode ]; then
        echo "---- START checking on type R file ---  `date +%H%M%S`" | tee -a $LOGFILE $TMPLOG
        ${ROOT_PATH}/checkinput_mvCrate_typeR.sh /tmp/ProcessMvCrate_${DATE}-${TIME}.barcode ${ELEMENT_LOG} ${DATE}-${TIME}
        ERRCODE=`expr $ERRCODE + $?`
        # Call "findOBject_inCrate_typeR.sh" separately (instead of
        # inside "checkinput_mvCrate_typeR.sh to enable independent
        # error) to get all the objects associated w/ the crate.
        # The output from this call is "/tmp/all_crateObj.tab.${TIMESTAMP}"
        # (fields: objectnumber, computedcrate, computedcurrentlocation), Talend will
        # need to match the crate to know which objects to move to where 
        # ${ROOT_PATH}/findObject_inCrate_typeR.sh /tmp/ProcessMvCrate_${DATE}-${TIME}.barcode ${DATE}-${TIME}
        # Passing pre-processed crate locations from the previous step
        # 4/30/2014 --- keep missing objects that are just put into the crate (ran from last file),
        #               so put in another 30 sec delay before calling "find..."
        #               (also now added a 5s  delay added between each run)
        sleep 0s
        ${ROOT_PATH}/findObject_inVerifiedCrate_typeR.sh /tmp/crate_mvCrate.out.${DATE}-${TIME} ${DATE}-${TIME}
        ERRCODE=`expr $ERRCODE + $?`
        # reset to have "crate" search on (NOCRATE=0)
        NOCRATE=0
        echo "---- END checking on type R file --- `date +%H%M%S`" | tee -a $LOGFILE $TMPLOG
    fi

    # echo "ERRCODE=$ERRCODE, gotit=$gotit"
    skip=0        # flag to signal if import should be skipped
    if [ ${ERRCODE} -gt 0 ]; then
        echo ""
        gotit=0        # only non-interactive, or interactive answering y/n will set gotit=1
        while [ $gotit -lt 1 ]; do
            if [ $_interactive -eq 0 ]; then
                mv $SINGLEFL ${ROOT_PATH}/bad_barcode
                echo "" >> ${ELEMENT_LOG}
                echo "LMI records creation aborted!" >> ${ELEMENT_LOG}
                BADFL=`echo $SINGLEFL | sed -e 's/^.*\.barcode/.barcode/'`
                echo "file $BADFL is moved to \"bad_barcode\" directory." >> ${ELEMENT_LOG}
                echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> ${ELEMENT_LOG}
                gotit=1
                skip=1
            else        # interactive mode
                read -p "ABORT proceess of creating the LMI records (y/n)?"
                if [ "$REPLY" == "y" ]; then
                    mv $SINGLEFL ${ROOT_PATH}/bad_barcode
                    echo "" >> ${ELEMENT_LOG}
                    echo "LMI records creation aborted!" >> ${ELEMENT_LOG}
                    BADFL=`echo $SINGLEFL | sed -e 's/^.*\.barcode/.barcode/'`
                    echo "file $BADFL is moved to \"bad_barcode\" directory." >> ${ELEMENT_LOG}
                    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> ${ELEMENT_LOG}
                    gotit=1
                    skip=1
                elif [ "$REPLY" == "n" ]; then
                    echo "Newly created LMI records will contain errors!" | tee -a ${ELEMENT_LOG}
                    echo "They have to be fixed manually." | tee -a ${ELEMENT_LOG}
                    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> ${ELEMENT_LOG}
                    gotit=1
                fi
            fi        # end of interactive mode
        done    # end of while loop
    fi        # end of ERRCODE checking interactive/not

    # echo "ERRCODE=$ERRCODE, gotit=$gotit"
    cat ${ELEMENT_LOG} >> $LOGFILE 
    cat ${ELEMENT_LOG} >> $TMPLOG

    if [ $skip -eq 0 ]; then

        # 12/11/2013 Move the original file to temporary holding directory,
        #            so if Talend job run & "import" portion takes longer 
        #               then the cron job spaced duration (currently 1hr).
        mv $SINGLEFL ${ROOT_PATH}/holding
        SINGLEFLNM=$(basename $SINGLEFL)
        echo "moving $SINGLEFLNM to holding directory" | tee -a $LOGFILE $TMPLOG

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # prepare files for Talend jobs (now use external tab-delimited files for 
        # handler, object, loc & crate, so Talend job don't need to load all
        # records in the database)
        ${ROOT_PATH}/talendinput_typeR.sh ${DATE}-${TIME} $NOCRATE

        wc -l /tmp/Process5_${DATE}-${TIME}.barcode  | tee -a $LOGFILE $TMPLOG
        wc -l /tmp/Process6_${DATE}-${TIME}.barcode  | tee -a $LOGFILE $TMPLOG
        wc -l /tmp/ProcessMvCrate_${DATE}-${TIME}.barcode  | tee -a $LOGFILE $TMPLOG

        # continue;

        echo "" | tee -a $LOGFILE $TMPLOG

        echo "----- Running Talend job (type 'M')..."
        cd ${ROOT_PATH}/TMSlocation_barcode_5fld
        TALEND5_PATH=${ROOT_PATH}/TMSlocation_barcode_5fld
        # java -Xms256M -Xmx1024M -cp classpath.jar: pahma_etl.tmslocation_barcode_5fld_1_0.TMSlocation_barcode_5fld --context=Default --context_param infile_min="${TIME}" 
        java -Xms256M -Xmx1024M -cp $TALEND5_PATH/../lib/advancedPersistentLookupLib-1.0.jar:$TALEND5_PATH/../lib/commons-collections-3.2.jar:$TALEND5_PATH/../lib/dom4j-1.6.1.jar:$TALEND5_PATH/../lib/external_sort.jar:$TALEND5_PATH/../lib/jaxen-1.1.1.jar:$TALEND5_PATH/../lib/jboss-serialization.jar:$TALEND5_PATH/../lib/log4j-1.2.15.jar:$TALEND5_PATH/../lib/talendcsv.jar:$TALEND5_PATH/../lib/talend_file_enhanced_20070724.jar:$TALEND5_PATH/../lib/trove.jar:$TALEND5_PATH:$TALEND5_PATH/../lib/systemRoutines.jar:$TALEND5_PATH/../lib/userRoutines.jar::.:$TALEND5_PATH/tmslocation_barcode_5fld_1_1.jar: pahma_etl.tmslocation_barcode_5fld_1_1.TMSlocation_barcode_5fld --context=Default --context_param infile_min="${TIME}" 

        echo "----- Running Talend job (type 'C')..."
        cd ${ROOT_PATH}/TMSlocation_barcode_6fld
        TALEND6_PATH=${ROOT_PATH}/TMSlocation_barcode_6fld
        # java -Xms256M -Xmx1024M -cp classpath.jar: pahma_etl.tmslocation_barcode_6fld_1_0.TMSlocation_barcode_6fld --context=Default --context_param infile_min="${TIME}"
        java -Xms256M -Xmx1024M -cp $TALEND6_PATH/../lib/advancedPersistentLookupLib-1.0.jar:$TALEND6_PATH/../lib/commons-collections-3.2.jar:$TALEND6_PATH/../lib/dom4j-1.6.1.jar:$TALEND6_PATH/../lib/external_sort.jar:$TALEND6_PATH/../lib/jaxen-1.1.1.jar:$TALEND6_PATH/../lib/jboss-serialization.jar:$TALEND6_PATH/../lib/log4j-1.2.15.jar:$TALEND6_PATH/../lib/talendcsv.jar:$TALEND6_PATH/../lib/talend_file_enhanced_20070724.jar:$TALEND6_PATH/../lib/trove.jar:$TALEND6_PATH:$TALEND6_PATH/../lib/systemRoutines.jar:$TALEND6_PATH/../lib/userRoutines.jar::.:$TALEND6_PATH/tmslocation_barcode_6fld_1_1.jar: pahma_etl.tmslocation_barcode_6fld_1_1.TMSlocation_barcode_6fld --context=Default --context_param infile_min="${TIME}"

        echo "----- Running Talend job (type 'R')..."
        cd ${ROOT_PATH}/TMSlocation_barcode_mvCrate
        TALENDMVCRATE_PATH=${ROOT_PATH}/TMSlocation_barcode_mvCrate
        echo "---- START Talend on type R file --- `date +%H%M%S`" | tee -a $LOGFILE $TMPLOG
 java -Xms256M -Xmx1536M -cp $TALENDMVCRATE_PATH/../lib/advancedPersistentLookupLib-1.0.jar:$TALENDMVCRATE_PATH/../lib/commons-collections-3.2.jar:$TALENDMVCRATE_PATH/../lib/dom4j-1.6.1.jar:$TALENDMVCRATE_PATH/../lib/external_sort.jar:$TALENDMVCRATE_PATH/../lib/jaxen-1.1.1.jar:$TALENDMVCRATE_PATH/../lib/jboss-serialization.jar:$TALENDMVCRATE_PATH/../lib/log4j-1.2.15.jar:$TALENDMVCRATE_PATH/../lib/talendcsv.jar:$TALENDMVCRATE_PATH/../lib/talend_file_enhanced_20070724.jar:$TALENDMVCRATE_PATH/../lib/trove.jar:$TALENDMVCRATE_PATH:$TALENDMVCRATE_PATH/../lib/systemRoutines.jar:$TALENDMVCRATE_PATH/../lib/userRoutines.jar::.:$TALENDMVCRATE_PATH/tmslocation_barcode_mvcrate_1_1.jar: pahma_etl.tmslocation_barcode_mvcrate_1_1.TMSlocation_barcode_mvCrate --context=Default --context_param infile_min="${TIME}"
        echo "---- END Talend on type R file --- `date +%H%M%S`" | tee -a $LOGFILE $TMPLOG

        echo "done."

        # continue;

        LMIDIR=${ROOT_PATH}/temp/location
        LMI5_IMPORTS=$LMIDIR/barcode5.${DATE}-${TIME}*.xml
        LMI5_CSID=$LMIDIR/barcode5_CSID.${DATE}-${TIME}*.txt
        LMI5_ID=$LMIDIR/barcode5_ID.${DATE}-${TIME}*.txt
        LMI6_IMPORTS=$LMIDIR/barcode6.${DATE}-${TIME}*.xml
        LMI6_CSID=$LMIDIR/barcode6_CSID.${DATE}-${TIME}*.txt
        LMI6_ID=$LMIDIR/barcode6_ID.${DATE}-${TIME}*.txt
        LMIMVCRATE_IMPORTS=$LMIDIR/barcodeMvCrate.${DATE}-${TIME}*.xml
        LMIMVCRATE_CSID=$LMIDIR/barcodeMvCrate_CSID.${DATE}-${TIME}*.txt
        LMIMVCRATE_ID=$LMIDIR/barcodeMvCrate_ID.${DATE}-${TIME}*.txt

        LMI_CURLOUT=$LMIDIR/*${DATE}-${TIME}*.curl.out
        LMI_DONEDIR=$LMIDIR/done
        LMI_ID_DIR=$LMIDIR/done_id
        wc -l $LMI5_CSID $LMI6_CSID $LMIMVCRATE_CSID | tee -a $LOGFILE $TMPLOG

        echo ""
        echo "----- Importing LMI records ..."
         for PREDATA in $LMI5_IMPORTS $LMI6_IMPORTS $LMIMVCRATE_IMPORTS; do
             if [ ! -s $PREDATA ]; then
                 continue
             fi
 
             ROOT=${PREDATA%\.*}
             DATA=${ROOT}.fixed.xml
             CURLOUT=${DATA}.curl.out
             sed -e 's/&amp;#x0A/\&#x0A/g' $PREDATA | sed -e 's/schema0/schema/' | sed -e 's/schema2/schema/' > ${DATA}
             echo "Import barcode file=$DATA `date +%H%M%S`" | tee -a $LOGFILE $TMPLOG
             attempts=0
             while [ $attempts -le 2 ]
             do
                 curl -s -X POST ${URL}?impTimout=900 -i -u "$USER" -H "$CONTENT_TYPE" -T $DATA -o ${CURLOUT}
                 if grep -q "Unable to commit/rollback" ${CURLOUT}
                 then
                     echo "PAHMA commit error detected; retrying ${DATA} ---" >> $LOGFILE
                     attempts=$(( $attempts + 1 ))
                 else
                     # assume succcess, or other unrecoverable error; bail out.
                     attempts=10
                 fi
             done
             echo "END Import barcode file=$DATA `date +%H%M%S`" | tee -a $LOGFILE $TMPLOG
 
             # Cout number of import records read by "curl" and append to a log file.
             echo "Barcode movement --- Counting $DATA ---" >> $LOGFILE
             grep READ ${CURLOUT} | wc -l >> $LOGFILE

            # 1/28/2014 Also send import count to user email (for debugging)
            DATAFILE=$(basename "$DATA")
            echo "Barcode movement --- Counting $DATAFILE ---" >> ${ELEMENT_LOG}
            grep READ ${CURLOUT} | wc -l >> ${ELEMENT_LOG}
         done
        echo ">> importing barcode LMI record done."

        echo ""
        RELDIR=${ROOT_PATH}/temp/relation
        LMI2OBJ_IMPORT5=$RELDIR/barcode5_move2obj.${DATE}-${TIME}*.xml
        OBJ2LMI_IMPORT5=$RELDIR/barcode5_obj2move.${DATE}-${TIME}*.xml
        LMI2OBJ_IMPORT6=$RELDIR/barcode6_move2obj.${DATE}-${TIME}*.xml
        OBJ2LMI_IMPORT6=$RELDIR/barcode6_obj2move.${DATE}-${TIME}*.xml
        LMI2OBJ_IMPORTMVCRATE=$RELDIR/barcodeMvCrate_move2obj.${DATE}-${TIME}*.xml
        OBJ2LMI_IMPORTMVCRATE=$RELDIR/barcodeMvCrate_obj2move.${DATE}-${TIME}*.xml

        REL_CURLOUT=$RELDIR/*${DATE}-${TIME}*.curl.out
        REL_DONEDIR=$RELDIR/done

        echo "----- Barcode movement & objects relation records-----"
         for PREDATA in $LMI2OBJ_IMPORT5 $OBJ2LMI_IMPORT5 $LMI2OBJ_IMPORT6 $OBJ2LMI_IMPORT6 $LMI2OBJ_IMPORTMVCRATE $OBJ2LMI_IMPORTMVCRATE; do
             if [ ! -s $PREDATA ]; then
                 continue
             fi
 
             ROOT=${PREDATA%\.*}
             DATA=${ROOT}.fixed.xml
             CURLOUT=${DATA}.curl.out
             sed -e 's/schema0/schema/' $PREDATA > ${DATA}
             echo "Import move-obj relationship file=$DATA  `date +%H%M%S`" | tee -a $LOGFILE $TMPLOG
             CURLOUT=${DATA}.curl.out
             attempts=0
             while [ $attempts -le 2 ]
             do
                 curl -s -X POST ${URL}?impTimout=900 -i -u "$USER" -H "$CONTENT_TYPE" -T $DATA -o ${CURLOUT}
                 if grep -q "Unable to commit/rollback" ${CURLOUT}
                 then
                     echo "PAHMA commit error detected; retrying ${DATA} ---" >> $LOGFILE
                     attempts=$(( $attempts + 1 ))
                 else
                     # assume succcess, or other unrecoverable error; bail out.
                     attempts=10
                 fi
             done
             echo "END Import move-obj relationship file=$DATA  `date +%H%M%S`" | tee -a $LOGFILE $TMPLOG
 
             # Count number of import records read by "curl" and append to a log file.
             echo "Barcode LMI-Obj relationship --- Counting $DATA ---" >> $LOGFILE
             grep READ ${CURLOUT} | wc -l >> $LOGFILE
 
            # 1/28/2014 Also send import count to user email (for debugging)
            DATAFILE=$(basename "$DATA")
            echo "Barcode LMI-Obj relationship --- Counting $DATAFILE ---" >> ${ELEMENT_LOG}
            grep READ ${CURLOUT} | wc -l >> ${ELEMENT_LOG}

         done
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> $LOGFILE
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" >> ${ELEMENT_LOG}
        echo ">> importing LMI-obj relationship record done."

        cat $TMPLOG >> $CUMLOG
        rm $TMPLOG
        mv ${ROOT_PATH}/holding/$SINGLEFLNM ${ROOT_PATH}/processed
        mv /tmp/Process5_${DATE}-${TIME}.barcode ${ROOT_PATH}/processed
        mv /tmp/Process6_${DATE}-${TIME}.barcode ${ROOT_PATH}/processed
        mv /tmp/ProcessMvCrate_${DATE}-${TIME}.barcode ${ROOT_PATH}/processed

        # Need to move the XML files away so they don't get processed again as part of 
        # new run (if multi-runs in a day, wild card will include older files)
        for LMIDONE in $LMI5_IMPORTS $LMI6_IMPORTS $LMIMVCRATE_IMPORTS $LMI_CURLOUT; do
            gzip $LMIDONE
            mv ${LMIDONE}.gz $LMI_DONEDIR
        done
        for LMI_ID in $LMI5_ID $LMI6_ID $LMIMVCRATE_ID $LMI5_CSID $LMI6_CSID $LMIMVCRATE_CSID; do
            mv $LMI_ID $LMI_ID_DIR
        done

        for RELDONE in $LMI2OBJ_IMPORT5 $OBJ2LMI_IMPORT5 $LMI2OBJ_IMPORT6 $OBJ2LMI_IMPORT6 $LMI2OBJ_IMPORTMVCRATE $OBJ2LMI_IMPORTMVCRATE $REL_CURLOUT; do
            gzip $RELDONE
            mv ${RELDONE}.gz $REL_DONEDIR
        done
        # 12/11/2013 Keep the following line commented out for now (for debugging)
        # rm /tmp/all_*.tab.${DATE}-${TIME}
    fi

    # clean up the files used for checking handlers/objects/locations/crates
    if [ -f ${ROOT_PATH}/processed/Process5_${DATE}-${TIME}.barcode ]; then
        rm /tmp/handler5.*.${DATE}-${TIME} /tmp/obj5.*.${DATE}-${TIME} /tmp/loc5.*.${DATE}-${TIME}  
    fi
    if [ -f ${ROOT_PATH}/processed/Process6_${DATE}-${TIME}.barcode ]; then
        rm /tmp/handler6.*.${DATE}-${TIME} /tmp/obj6.*.${DATE}-${TIME} /tmp/loc6.*.${DATE}-${TIME} /tmp/crate6.*.${DATE}-${TIME}
    fi
    if [ -f ${ROOT_PATH}/processed/ProcessMvCrate_${DATE}-${TIME}.barcode ]; then
        rm /tmp/handler_mvCrate.*.${DATE}-${TIME} /tmp/newLoc_mvCrate.*.${DATE}-${TIME} /tmp/crate_mvCrate.*.${DATE}-${TIME}
    fi

    # 4/30/2014 --- keep missing objects (type R) that are just put into the crate (type C),
    #               so do a mandatory delay of 1 min between running each file.
    sleep 0s
done
+ for SINGLEFL in '${BARCODE_FILES}'
+ NOCRATE=0
+ ERRCODE=0
+ gotit=0
+ echo ''
+ tee -a /home/app_webapps/batch_barcode/log/Barcode_log.20150916-1402

+ echo '----- STARTING FILE /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT -----'
+ tee -a /home/app_webapps/batch_barcode/log/Barcode_log.20150916-1402
----- STARTING FILE /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT -----
date +%H%M%S
++ date +%H%M%S
+ TIME=140201
+ wc -l /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT
+ tee -a /home/app_webapps/batch_barcode/log/Barcode_log.20150916 /tmp/5170
143 /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT
+ grep '^"M",' /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT
+ uniq
+ sort
+ grep '^"C",' /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT
+ uniq
+ sort
+ grep '^"R",' /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT
+ uniq
+ sort
+ '[' -s /tmp/Process5_2015-09-16-140201.barcode ']'
+ /home/app_webapps/batch_barcode/checkinput_5fld.sh /tmp/Process5_2015-09-16-140201.barcode /home/app_webapps/batch_barcode/log/Barcode_log.20150916-1402 2015-09-16-140201
#!/bin/bash -vx

# CSV field locations for barcode 5 fields:
# "Type", "Handler", "Museum number", "New/curr location", "Timestamp for move/inventory"

# 10/24/2012 Now switch to use LocHandler.txt file for "handler" in the barcode file,
#            so slight change in creating /tmp/handler[56].in file & chk_handler variable
#
# 10/25/2012 The DATE-TIME is also passed to this "checkinput_[56]fld.sh" as the 3rd
#      argument, so the intermediate files used for checking are distinguishable
#      among the runs

# set environment variables for this run
source ~/batch_barcode/setBarcodeEnv.sh
+ source /home/app_webapps/batch_barcode/setBarcodeEnv.sh

#set verbose

# target server
export URL="https://pahma-dev.cspace.berkeley.edu/cspace-services/imports"
++ export URL=https://pahma-dev.cspace.berkeley.edu/cspace-services/imports
++ URL=https://pahma-dev.cspace.berkeley.edu/cspace-services/imports
export USER="import@pahma.cspace.berkeley.edu:lash428!puck"
++ export 'USER=import@pahma.cspace.berkeley.edu:lash428!puck'
++ USER='import@pahma.cspace.berkeley.edu:lash428!puck'
export CONTENT_TYPE="Content-Type: application/xml"
++ export 'CONTENT_TYPE=Content-Type: application/xml'
++ CONTENT_TYPE='Content-Type: application/xml'

# password comes from .pgpass
export CONNECTSTRING="host=dba-postgres-dev-32.ist.berkeley.edu port=5107 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma "
++ export 'CONNECTSTRING=host=dba-postgres-dev-32.ist.berkeley.edu port=5107 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma '
++ CONNECTSTRING='host=dba-postgres-dev-32.ist.berkeley.edu port=5107 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma '

# setup for email
export SUBJECT="Importing barcode LMI (C/M/R types)"
++ export 'SUBJECT=Importing barcode LMI (C/M/R types)'
++ SUBJECT='Importing barcode LMI (C/M/R types)'
export EMAIL="jblowe@berkeley.edu"
++ export EMAIL=jblowe@berkeley.edu
++ EMAIL=jblowe@berkeley.edu

export ROOT_PATH=/home/app_webapps/batch_barcode
++ export ROOT_PATH=/home/app_webapps/batch_barcode
++ ROOT_PATH=/home/app_webapps/batch_barcode
export UPLOAD_PATH=${ROOT_PATH}/input
++ export UPLOAD_PATH=/home/app_webapps/batch_barcode/input
++ UPLOAD_PATH=/home/app_webapps/batch_barcode/input
#EMAIL3="pahma-tricoder@lists.berkeley.edu"
# UPLOAD_PATH=/tmp/tricoder_typeR


if [ $# -lt 2 ]; then
    echo "Usage: checkinput_5fld input_filename errlog_filename datetime_stamp"
    exit
fi
+ '[' 3 -lt 2 ']'

INFILE=$1
+ INFILE=/tmp/Process5_2015-09-16-140201.barcode
LOGFILE=$2
+ LOGFILE=/home/app_webapps/batch_barcode/log/Barcode_log.20150916-1402
TIMESTAMP=$3
+ TIMESTAMP=2015-09-16-140201
echo "" | tee -a $LOGFILE
+ echo ''
+ tee -a /home/app_webapps/batch_barcode/log/Barcode_log.20150916-1402

echo "Checking barcode file $INFILE (no crates) ... "  | tee -a $LOGFILE
+ echo 'Checking barcode file /tmp/Process5_2015-09-16-140201.barcode (no crates) ... '
+ tee -a /home/app_webapps/batch_barcode/log/Barcode_log.20150916-1402
Checking barcode file /tmp/Process5_2015-09-16-140201.barcode (no crates) ... 

echo "$CONNECTSTRING" | tee -a $LOGFILE
+ echo 'host=dba-postgres-dev-32.ist.berkeley.edu port=5107 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma '
+ tee -a /home/app_webapps/batch_barcode/log/Barcode_log.20150916-1402
host=dba-postgres-dev-32.ist.berkeley.edu port=5107 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma 

nerr=0
+ nerr=0

# Run a postgres command-line "sql" to get at nuxeo data
# psql returns a table w/ heading and '---' separator, as well as a blank and a 
# "total entry count" lines so need to strip off these before comparing w/ input

# ------ test handler (2nd field) -----
# cat $INFILE | perl -pe 's/^.*","(.*)",".*",".*",".*$/$1/' |sort |uniq > /tmp/handler5.in 
# chk_handler=`cat $INFILE | perl -pe 's/^.*","(.*)",".*",".*",".*$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
cat $INFILE | perl -pe 's/^.*","(.*)",".*",".*",.*$/$1/' |sort |uniq | perl ${ROOT_PATH}/handler.pl | sort > /tmp/handler5.in.${TIMESTAMP} 
+ cat /tmp/Process5_2015-09-16-140201.barcode
+ sort
+ perl /home/app_webapps/batch_barcode/handler.pl
+ uniq
+ perl -pe 's/^.*","(.*)",".*",".*",.*$/$1/'
+ sort
readline() on closed filehandle INFILE at /home/app_webapps/batch_barcode/handler.pl line 10.
sleep 3
+ sleep 3
# echo "handler5.in.${TIMESTAMP} before handler extraction contains the following lines: "
# cat /tmp/handler5.in.${TIMESTAMP}
chk_handler=`cat /tmp/handler5.in.${TIMESTAMP} | perl -pe 's/^(.*)$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
cat /tmp/handler5.in.${TIMESTAMP} | perl -pe 's/^(.*)$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\n"  | sed -e "s/,$//" 
++ cat /tmp/handler5.in.2015-09-16-140201
++ sed -e 's/,$//'
++ sort
++ uniq
++ tr -d '\n'
++ perl -pe 's/^(.*)$/\'\''$1\'\'',/'
+ chk_handler=''\''A2581770'\'''
# echo "handler5.in.${TIMESTAMP} contains: $chk_handler"
psql -X -d "$CONNECTSTRING" -c "select pt.termdisplayname from persontermgroup pt where pt.termdisplayname in ($chk_handler);" | awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' | sort |uniq > /tmp/handler5.out.${TIMESTAMP}
+ psql -X -d 'host=dba-postgres-dev-32.ist.berkeley.edu port=5107 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma ' -c 'select pt.termdisplayname from persontermgroup pt where pt.termdisplayname in ('\''A2581770'\'');'
+ uniq
+ sed -e '$d'
+ awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}'
+ sort
+ sed -e '$d'
# echo "handler5.out.${TIMESTAMP} from psql run contains the following lines: "
# cat /tmp/handler5.out.${TIMESTAMP}
comm -13 /tmp/handler5.out.${TIMESTAMP} /tmp/handler5.in.${TIMESTAMP} > /tmp/handler5.missing.${TIMESTAMP}
+ comm -13 /tmp/handler5.out.2015-09-16-140201 /tmp/handler5.in.2015-09-16-140201
if [ -s /tmp/handler5.missing.${TIMESTAMP} ]; then
   echo ">> The following HANDLER is NOT in CSpace database:" | tee -a $LOGFILE
   cat /tmp/handler5.missing.${TIMESTAMP} | tee -a $LOGFILE
   nerr=`expr $nerr + 1`
fi
+ '[' -s /tmp/handler5.missing.2015-09-16-140201 ']'
+ echo '>> The following HANDLER is NOT in CSpace database:'
+ tee -a /home/app_webapps/batch_barcode/log/Barcode_log.20150916-1402
>> The following HANDLER is NOT in CSpace database:
+ cat /tmp/handler5.missing.2015-09-16-140201
+ tee -a /home/app_webapps/batch_barcode/log/Barcode_log.20150916-1402
A2581770
expr $nerr + 1
++ expr 0 + 1
+ nerr=1

# ------ test object number (3rd field) -----
cat $INFILE | perl -pe 's/^.*",".*","(.*)",".*",".*$/$1/' |sort |uniq > /tmp/obj5.in.${TIMESTAMP}
+ cat /tmp/Process5_2015-09-16-140201.barcode
+ uniq
+ sort
+ perl -pe 's/^.*",".*","(.*)",".*",".*$/$1/'
chk_obj=`cat $INFILE | perl -pe 's/^.*",".*","(.*)",".*",".*$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
cat $INFILE | perl -pe 's/^.*",".*","(.*)",".*",".*$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\n"  | sed -e "s/,$//" 
++ cat /tmp/Process5_2015-09-16-140201.barcode
++ sed -e 's/,$//'
++ sort
++ uniq
++ tr -d '\n'
++ perl -pe 's/^.*",".*","(.*)",".*",".*$/\'\''$1\'\'',/'
+ chk_obj=''\''11-1159'\'','\''11-12273'\'','\''11-1343'\'','\''11-37082'\'','\''11-37357'\'','\''11-37662'\'','\''11-38040'\'','\''11-38467'\'','\''11-39102'\'','\''11-42919'\'','\''11-43525'\'','\''11-63'\'','\''11-64'\'','\''1-21690.1'\'','\''1-21690.2'\'','\''18-251a'\'','\''18-251b'\'','\''18-956'\'','\''2-2397'\'','\''5-10428'\'','\''5-13126'\'','\''5-13670'\'','\''5-13694'\'','\''5-14494'\'','\''5-2655'\'','\''5-2656'\'','\''5-2658'\'','\''5-4690'\'','\''5-5308'\'','\''5-7034'\'','\''5-7035'\'','\''5-8570'\'','\''9-11450'\'','\''9-11451'\'','\''9-11452'\'','\''9-11955'\'','\''9-12832a'\'','\''9-12845'\'','\''9-12846'\'','\''9-16189a,b'\'','\''9-16195a,b'\'','\''9-17881'\'','\''9-22098a,b'\'','\''9-22653'\'','\''9-22654'\'','\''9-5170'\'','\''9-5171'\'','\''9-5759'\'','\''No-Temp196'\'','\''No-Temp210'\'','\''NO-TEMP213'\'''
# echo $chk_obj
psql -X -d "$CONNECTSTRING" -c "select o.objectnumber from collectionobjects_common o where o.objectnumber in ($chk_obj);" | awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' | sort |uniq > /tmp/obj5.out.${TIMESTAMP}
+ psql -X -d 'host=dba-postgres-dev-32.ist.berkeley.edu port=5107 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma ' -c 'select o.objectnumber from collectionobjects_common o where o.objectnumber in ('\''11-1159'\'','\''11-12273'\'','\''11-1343'\'','\''11-37082'\'','\''11-37357'\'','\''11-37662'\'','\''11-38040'\'','\''11-38467'\'','\''11-39102'\'','\''11-42919'\'','\''11-43525'\'','\''11-63'\'','\''11-64'\'','\''1-21690.1'\'','\''1-21690.2'\'','\''18-251a'\'','\''18-251b'\'','\''18-956'\'','\''2-2397'\'','\''5-10428'\'','\''5-13126'\'','\''5-13670'\'','\''5-13694'\'','\''5-14494'\'','\''5-2655'\'','\''5-2656'\'','\''5-2658'\'','\''5-4690'\'','\''5-5308'\'','\''5-7034'\'','\''5-7035'\'','\''5-8570'\'','\''9-11450'\'','\''9-11451'\'','\''9-11452'\'','\''9-11955'\'','\''9-12832a'\'','\''9-12845'\'','\''9-12846'\'','\''9-16189a,b'\'','\''9-16195a,b'\'','\''9-17881'\'','\''9-22098a,b'\'','\''9-22653'\'','\''9-22654'\'','\''9-5170'\'','\''9-5171'\'','\''9-5759'\'','\''No-Temp196'\'','\''No-Temp210'\'','\''NO-TEMP213'\'');'
+ uniq
+ sed -e '$d'
+ awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}'
+ sort
+ sed -e '$d'
comm -13 /tmp/obj5.out.${TIMESTAMP} /tmp/obj5.in.${TIMESTAMP} > /tmp/obj5.missing.${TIMESTAMP}
+ comm -13 /tmp/obj5.out.2015-09-16-140201 /tmp/obj5.in.2015-09-16-140201
if [ -s /tmp/obj5.missing.${TIMESTAMP} ]; then
   echo ">> The following MUSEUM NUMBER is NOT in CSpace database:"  | tee -a $LOGFILE
   cat /tmp/obj5.missing.${TIMESTAMP}  | tee -a $LOGFILE
   nerr=`expr $nerr + 1`
fi
+ '[' -s /tmp/obj5.missing.2015-09-16-140201 ']'

# ------ test storage location (4th field) -----
cat $INFILE | perl -pe 's/^.*",".*",".*","(.*)",".*$/$1/' |sort |uniq > /tmp/loc5.in.${TIMESTAMP}
+ cat /tmp/Process5_2015-09-16-140201.barcode
+ uniq
+ sort
+ perl -pe 's/^.*",".*",".*","(.*)",".*$/$1/'
chk_loc=`cat $INFILE | perl -pe 's/^.*",".*",".*","(.*)",".*$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\\n"  | sed -e "s/,$//" `
cat $INFILE | perl -pe 's/^.*",".*",".*","(.*)",".*$/''\'\''$1''\'\'',/' |sort |uniq | tr -d "\n"  | sed -e "s/,$//" 
++ cat /tmp/Process5_2015-09-16-140201.barcode
++ sed -e 's/,$//'
++ tr -d '\n'
++ uniq
++ sort
++ perl -pe 's/^.*",".*",".*","(.*)",".*$/\'\''$1\'\'',/'
+ chk_loc=''\''Regatta, A140, 10C, 2'\'','\''Regatta, A140, 1B, 2'\'','\''Regatta, A140, 2A, 3'\'','\''Regatta, A140, 2B, 3'\'','\''Regatta, A140, 2B, 4'\'','\''Regatta, A140, 2B, 5'\'','\''Regatta, A140, 7A, 3'\'','\''Regatta, A140, 7B, 3'\'','\''Regatta, A140, 7C, 3'\'','\''Regatta, A140, 8C, 3'\'','\''Regatta, A150, M03, 01'\'','\''Regatta, A150, N07, 02'\'','\''Regatta, A150, O06, 02'\'','\''Regatta, A150, Q01, 02'\'','\''Regatta, A150, Q03, 10'\'','\''Regatta, A150, Q09, 07'\'','\''Regatta, A150, R07, 03'\'','\''Regatta, A150, R08, 02'\'','\''Regatta, A150, R09, 01'\'','\''Regatta, A150, R09, 02'\'','\''Regatta, A150, S06, 01'\'','\''Regatta, A150, S07, 01'\'','\''Regatta, A150, S08, 01'\'','\''Regatta, A150, S08, 02'\'','\''Regatta, A150, S08, 03'\'','\''Regatta, A150, S08, 04'\'','\''Regatta, A150, S08, 05'\'','\''Regatta, A150, S08, 06'\'','\''Regatta, A150, S09, 01'\'','\''Regatta, A150, S09, 02'\'','\''Regatta, A150, S09, 09'\'','\''Regatta, A150, T01, 05'\'','\''Regatta, A150, U01, 03'\'''
# echo $chk_loc
psql -X -d "$CONNECTSTRING" -c "select lt.termdisplayname from loctermgroup lt where lt.termdisplayname in ($chk_loc);" | awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}' | sed -e '$d' | sed -e '$d' | sort |uniq > /tmp/loc5.out.${TIMESTAMP}
+ psql -X -d 'host=dba-postgres-dev-32.ist.berkeley.edu port=5107 sslmode=prefer dbname=pahma_domain_pahma user=reporter_pahma ' -c 'select lt.termdisplayname from loctermgroup lt where lt.termdisplayname in ('\''Regatta, A140, 10C, 2'\'','\''Regatta, A140, 1B, 2'\'','\''Regatta, A140, 2A, 3'\'','\''Regatta, A140, 2B, 3'\'','\''Regatta, A140, 2B, 4'\'','\''Regatta, A140, 2B, 5'\'','\''Regatta, A140, 7A, 3'\'','\''Regatta, A140, 7B, 3'\'','\''Regatta, A140, 7C, 3'\'','\''Regatta, A140, 8C, 3'\'','\''Regatta, A150, M03, 01'\'','\''Regatta, A150, N07, 02'\'','\''Regatta, A150, O06, 02'\'','\''Regatta, A150, Q01, 02'\'','\''Regatta, A150, Q03, 10'\'','\''Regatta, A150, Q09, 07'\'','\''Regatta, A150, R07, 03'\'','\''Regatta, A150, R08, 02'\'','\''Regatta, A150, R09, 01'\'','\''Regatta, A150, R09, 02'\'','\''Regatta, A150, S06, 01'\'','\''Regatta, A150, S07, 01'\'','\''Regatta, A150, S08, 01'\'','\''Regatta, A150, S08, 02'\'','\''Regatta, A150, S08, 03'\'','\''Regatta, A150, S08, 04'\'','\''Regatta, A150, S08, 05'\'','\''Regatta, A150, S08, 06'\'','\''Regatta, A150, S09, 01'\'','\''Regatta, A150, S09, 02'\'','\''Regatta, A150, S09, 09'\'','\''Regatta, A150, T01, 05'\'','\''Regatta, A150, U01, 03'\'');'
+ uniq
+ sed -e '$d'
+ awk '1<=NR && NR<=2 {next}{sub(/^[ ]+/,"")}{print}'
+ sed -e '$d'
+ sort
comm -13 /tmp/loc5.out.${TIMESTAMP} /tmp/loc5.in.${TIMESTAMP} > /tmp/loc5.missing.${TIMESTAMP}
+ comm -13 /tmp/loc5.out.2015-09-16-140201 /tmp/loc5.in.2015-09-16-140201
if [ -s /tmp/loc5.missing.${TIMESTAMP} ]; then
   echo ">> The following LOCATION is NOT in CSpace database:"  | tee -a $LOGFILE
   cat /tmp/loc5.missing.${TIMESTAMP}  | tee -a $LOGFILE
   nerr=`expr $nerr + 1`
fi
+ '[' -s /tmp/loc5.missing.2015-09-16-140201 ']'

if [ $nerr -eq 0 ]; then
	echo "No error in barcode file $INFILE (no crates)."  | tee -a $LOGFILE
    exit 0
else
    exit 1
fi
+ '[' 1 -eq 0 ']'
+ exit 1
expr $ERRCODE + $?
++ expr 0 + 1
+ ERRCODE=1
+ '[' -s /tmp/Process6_2015-09-16-140201.barcode ']'
+ NOCRATE=1
+ '[' -s /tmp/ProcessMvCrate_2015-09-16-140201.barcode ']'
+ skip=0
+ '[' 1 -gt 0 ']'
+ echo ''

+ gotit=0
+ '[' 0 -lt 1 ']'
+ '[' 0 -eq 0 ']'
+ mv /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT /home/app_webapps/batch_barcode/bad_barcode
+ echo ''
+ echo 'LMI records creation aborted!'
echo $SINGLEFL | sed -e 's/^.*\.barcode/.barcode/'
++ echo /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT
++ sed -e 's/^.*\.barcode/.barcode/'
+ BADFL=/home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT
+ echo 'file /home/app_webapps/batch_barcode/input/barcode.TRIDATA_2015-09-16_JBLtest.DAT is moved to "bad_barcode" directory.'
+ echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
+ gotit=1
+ skip=1
+ '[' 1 -lt 1 ']'
+ cat /home/app_webapps/batch_barcode/log/Barcode_log.20150916-1402
+ cat /home/app_webapps/batch_barcode/log/Barcode_log.20150916-1402
+ '[' 1 -eq 0 ']'
+ '[' -f /home/app_webapps/batch_barcode/processed/Process5_2015-09-16-140201.barcode ']'
+ '[' -f /home/app_webapps/batch_barcode/processed/Process6_2015-09-16-140201.barcode ']'
+ '[' -f /home/app_webapps/batch_barcode/processed/ProcessMvCrate_2015-09-16-140201.barcode ']'
+ sleep 0s

/bin/mail -s "${SUBJECT}" "${EMAIL}" < ${ELEMENT_LOG}
+ /bin/mail -s 'Importing barcode LMI (C/M/R types)' jblowe@berkeley.edu
exit 0
+ exit 0
