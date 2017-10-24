#!/bin/bash -xv

# 2/20/2017 updated java calls for new version of Talend jobs; see PAHMA-1545
#
# 2/17/2016 refactored a good deal for managed servers and parameterization
#
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

m=`date '+%m'`  # init to today's month/day/year
d=`date '+%d'`
y=`date '+%Y'`
DATE=${y}-${m}-${d}
# TIME=`date +%k%M`        # 24-hr format as single digit string
TIME=`date +%H%M`        # this will keep leading zero on the hour


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
# echo "interactive = $_interactive"

# ELEMENT_LOG records what's going on in the run of "checkinput_5fld.sh" & "checkinput_6fld.sh"
# If error condition occurred, this should be mailed to the designated email
ELEMENT_LOG=${ROOT_PATH}/log/Barcode_log.$y$m$d-${TIME}

LOGFILE=${ROOT_PATH}/log/Barcode_log.$y$m$d
CUMLOG=${ROOT_PATH}/log/ALL_Barcode_LOG
TMPLOG=/tmp/$$

echo "$DATE $TIME" | tee -a $LOGFILE $TMPLOG
echo "Processing new barcode files" |tee -a $LOGFILE $TMPLOG

# find number of files matching the barcode file pattern
files=$(ls ${UPLOAD_PATH}/barcode.TRIDATA_${DATE}_*.DAT 2> /dev/null | wc -l)
echo "number of files to process: $files"
if [ "$files" == "0" ]; then
    echo "No barcode files to process ..." |tee -a $LOGFILE $TMPLOG
    # Probably don't need email if there is no file to process?
    # /bin/mail -s "${SUBJECT}" "${EMAIL}" < ${TMPLOG}
    # /bin/mail -s "${SUBJECT}" "${EMAIL2}" < ${TMPLOG}
    exit 0
fi

# Processing files according to upload time (earlier one on the top (ls -ltr))
echo "$DATE $TIME --- Processing the following file(s):" > ${ELEMENT_LOG}
ls -ltr ${UPLOAD_PATH}/barcode.TRIDATA_${DATE}*.DAT |sed -e 's/^.*apache [ 0-9][ 0-9]* //' | sed -e 's/\/home\/developers\/barcode\///' | tee -a ${ELEMENT_LOG}
BARCODE_FILES=`ls -ltr ${UPLOAD_PATH}/barcode.TRIDATA_${DATE}*.DAT | sed -e 's/^.* //' `

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
        java -Xms256M -Xmx1024M -cp $TALEND5_PATH/../lib/advancedPersistentLookupLib-1.0.jar:$TALEND5_PATH/../lib/commons-collections-3.2.jar:$TALEND5_PATH/../lib/dom4j-1.6.1.jar:$TALEND5_PATH/../lib/external_sort.jar:$TALEND5_PATH/../lib/jaxen-1.1.1.jar:$TALEND5_PATH/../lib/jboss-serialization.jar:$TALEND5_PATH/../lib/log4j-1.2.15.jar:$TALEND5_PATH/../lib/talendcsv.jar:$TALEND5_PATH/../lib/talend_file_enhanced_20070724.jar:$TALEND5_PATH/../lib/trove.jar:$TALEND5_PATH:$TALEND5_PATH/../lib/systemRoutines.jar:$TALEND5_PATH/../lib/userRoutines.jar::.:$TALEND5_PATH/tmslocation_barcode_5fld_1_2.jar: pahma.tmslocation_barcode_5fld_1_2.TMSlocation_barcode_5fld --context=Default --context_param infile_min="${TIME}" 

        echo "----- Running Talend job (type 'C')..."
        cd ${ROOT_PATH}/TMSlocation_barcode_6fld
        TALEND6_PATH=${ROOT_PATH}/TMSlocation_barcode_6fld
        # java -Xms256M -Xmx1024M -cp classpath.jar: pahma_etl.tmslocation_barcode_6fld_1_0.TMSlocation_barcode_6fld --context=Default --context_param infile_min="${TIME}"
        java -Xms256M -Xmx1024M -cp $TALEND6_PATH/../lib/advancedPersistentLookupLib-1.0.jar:$TALEND6_PATH/../lib/commons-collections-3.2.jar:$TALEND6_PATH/../lib/dom4j-1.6.1.jar:$TALEND6_PATH/../lib/external_sort.jar:$TALEND6_PATH/../lib/jaxen-1.1.1.jar:$TALEND6_PATH/../lib/jboss-serialization.jar:$TALEND6_PATH/../lib/log4j-1.2.15.jar:$TALEND6_PATH/../lib/talendcsv.jar:$TALEND6_PATH/../lib/talend_file_enhanced_20070724.jar:$TALEND6_PATH/../lib/trove.jar:$TALEND6_PATH:$TALEND6_PATH/../lib/systemRoutines.jar:$TALEND6_PATH/../lib/userRoutines.jar::.:$TALEND6_PATH/tmslocation_barcode_6fld_1_2.jar: pahma.tmslocation_barcode_6fld_1_2.TMSlocation_barcode_6fld --context=Default --context_param infile_min="${TIME}"

        echo "----- Running Talend job (type 'R')..."
        cd ${ROOT_PATH}/TMSlocation_barcode_mvCrate
        TALENDMVCRATE_PATH=${ROOT_PATH}/TMSlocation_barcode_mvCrate
        echo "---- START Talend on type R file --- `date +%H%M%S`" | tee -a $LOGFILE $TMPLOG
 java -Xms256M -Xmx1536M -cp $TALENDMVCRATE_PATH/../lib/advancedPersistentLookupLib-1.0.jar:$TALENDMVCRATE_PATH/../lib/commons-collections-3.2.jar:$TALENDMVCRATE_PATH/../lib/dom4j-1.6.1.jar:$TALENDMVCRATE_PATH/../lib/external_sort.jar:$TALENDMVCRATE_PATH/../lib/jaxen-1.1.1.jar:$TALENDMVCRATE_PATH/../lib/jboss-serialization.jar:$TALENDMVCRATE_PATH/../lib/log4j-1.2.15.jar:$TALENDMVCRATE_PATH/../lib/talendcsv.jar:$TALENDMVCRATE_PATH/../lib/talend_file_enhanced_20070724.jar:$TALENDMVCRATE_PATH/../lib/trove.jar:$TALENDMVCRATE_PATH:$TALENDMVCRATE_PATH/../lib/systemRoutines.jar:$TALENDMVCRATE_PATH/../lib/userRoutines.jar::.:$TALENDMVCRATE_PATH/tmslocation_barcode_mvcrate_1_2.jar: pahma.tmslocation_barcode_mvcrate_1_2.TMSlocation_barcode_mvCrate --context=Default --context_param infile_min="${TIME}"
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

/bin/mail -s "${SUBJECT}" "${EMAIL}" < ${ELEMENT_LOG}
exit 0
