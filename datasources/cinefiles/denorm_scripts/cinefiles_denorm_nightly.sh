#!/bin/bash
#
# Script for nightly update of cinefiles_denorm tables. Reads a list of 
# SQL files (script.list) and submits each file in turn, via psql, to the
# Postgresql database.
#
# To minimize downtime, new tables are created with temporary names.
# After all of the tables have been successfully created, they are
# renamed in a single batch. Then, finally, one more batch file is
# executed to create indexes.
#
# This should be installed in /home/cinefiles/bin.
# The SQL files are in /home/cinefiles/denorm_scripts
# Log files are in /home/cinefiles/logs

export PATH=/bin:/usr/bin:/home/cinefiles/bin
export PGUSER=nuxeo
export PGDATABASE=cinefiles_domain
export PGHOST=localhost

export SQLDIR="/home/cinefiles/denorm_scripts"
export LOGDIR="/home/cinefiles/logs"
export LOGFILE="$LOGDIR/denorm_nightly.log.$(date +'%d')"
export LOGLEVEL=3

[ -d "$LOGDIR" ] && [ -n "$LOGFILE" ] && touch "$LOGFILE"

function notify
{
   echo "NOTIFY: $1" | mail -s "cinefiles denorm" root
}

function log
{
   [ "$LOGLEVEL" -gt 0 ] && [ -f "$LOGFILE" ] && echo "$1" >> $LOGFILE
}

function trace
{
   [ "$LOGLEVEL" -gt 1 ] && [[ -t 0 ]] && echo "TRACE: $1"
   [ "$LOGLEVEL" -gt 2 ] && log "$1"
}

function exit_msg
{
   echo "$1" >&2
   notify "$1"
   exit 1
}

function stripws
{
   r=$(echo "$1 " | sed -e 's/^ *//' -e 's/ *$//')
   echo "${r###*}"
}

function comparetables
{
   re='^[0-9]+ [0-9]+$'
   [[ "$1 $2" =~ $re ]] && [ "$1" -le "$2" ] && return 0
   return 1;
}

log "Starting cinefiles_denorm_nightly at $(date)."

update_status=0
STATUSMSG="ALL DONE"
linecount=0

while read FILE
do
   linecount=$((linecount + 1))
   trace "${linecount}) READING: $FILE"

   SQL="$(stripws "$FILE")"
   [ -n "$SQL" ] || continue

   trace "USING: $(ls -l ${SQLDIR}/${SQL})"

   result=$(psql -q -t -f "${SQLDIR}/${SQL}")
   trace "RESULT: $result"

   if ! comparetables $result
   then
      update_status=$((update_status+1))
      STATUSMSG="Table counts DO NOT agree for $SQL. (Status: $update_status)"
      log $STATUSMSG
   else
      trace "Table counts DO agree for $SQL. (Status: $update_status)"
   fi
done < "${SQLDIR}/script.list"

trace "DONE LOOPING, STATUS = $update_status"

if [ "$update_status" -eq 0 ]
then
   trace "GETTING TABLE COUNTS"
   psql -q -t -f "${SQLDIR}/checkalltables.sql" > "${LOGDIR}/checkalltables.out" 2>&1
   trace "RENAMING TEMP TABLES (STATUS: $update_status)"
   result=$(psql -q -t -f "${SQLDIR}/rename_all.sql")
   log "RENAMED ALL FILES (STATUS: $update_status)"
   trace "CREATING INDEXES"
   result=$(psql -q -t -f "${SQLDIR}/create_indexes.sql")
else
   trace "BAILING"
   notify "$STATUSMSG (STATUS: $update_status)"
   exit_msg "$STATUSMSG (STATUS: $update_status)"
fi

trace "ALL DONE at `date`"
