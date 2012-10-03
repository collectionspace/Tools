#!/bin/bash

####################################################
# Script for creating a report record in multiple
# tenants via the CollectionSpace Services REST API.
#
# (While this is a special purpose, one-off script,
# this could also be generalized to create many
# different kinds of records.)
####################################################

####################################################
# Start of variables to set
####################################################

# Enable for verbose output - uncomment only while debugging!
# set -x verbose

# Set a space-separated list of tenant identifiers below:
TENANTS+=(core lifesci)

# This script assumes that each tenant's default administrator
# username follows a consistent pattern:
#   admin@{tenantidentifier}.collectionspace.org
# and that the passwords for each such account are identical,
# as per the variable set below:
DEFAULT_ADMIN_PASSWORD=Administrator

# Set the CollectionSpace hostname or IP address, and port below:
HOST=localhost
PORT=8180

####################################################
# End of variables to set
####################################################

DEFAULT_ADMIN_ACCTS+=()
let ACCT_COUNTER=0
for tenant in ${TENANTS[*]}
do
  DEFAULT_ADMIN_ACCTS[ACCT_COUNTER]="admin@$tenant.collectionspace.org"
  let ACCT_COUNTER++
done

CURL_EXECUTABLE=`which curl`
if [ "xCURL_EXECUTABLE" == "x" ]
  then
    echo "Could not find 'curl' application"
    exit 1
fi

LIST_ITEM_REGEX="list-item"
# Name of report file to match in a keyword search
REPORT_KEYWORD_TO_MATCH="acq_basic.jasper"
# FIXME: It may be prudent to add code to verify that any '401'
# response lines, not followed by 'Unauthorized', are truly
# response codes and not random occurrences of that number.
AUTHENTICATION_FAILURE_REGEX="^401 Unauthorized|^401"

let TENANT_COUNTER=0
for tenant in ${TENANTS[*]}
do

  tempfilename=`basename $0`
  # Three or more 'X's may be required in the template for the
  # temporary file name, under at least one or more Linux OSes
  READ_LIST_TMPFILE=`mktemp -t ${tempfilename}.XXXXX` || exit 1

  # As an admin user within this tenant, perform a keyword search
  # to find all existing records, if any, referring to this report
  
  echo "Checking for an Acquisition Summary report record in the '$tenant' tenant ..."

  $CURL_EXECUTABLE \
  --include \
  --silent \
  --user "${DEFAULT_ADMIN_ACCTS[TENANT_COUNTER]}:$DEFAULT_ADMIN_PASSWORD" \
  --url http://$HOST:$PORT/cspace-services/reports?kw=$REPORT_KEYWORD_TO_MATCH \
  > $READ_LIST_TMPFILE
  
  # Read the response from that file
  read_list_results=( $( < $READ_LIST_TMPFILE ) )
  
  # Check for possible authentication failure
  authentication_failure_flag=0
  for results_item in ${read_list_results[*]}
  do
    if [[ $results_item =~ $AUTHENTICATION_FAILURE_REGEX ]]; then
      authentication_failure_flag=1
      break
    fi
  done
  
  if [ $authentication_failure_flag == 1 ]; then
    echo "ERROR: Failed to authenticate successfully to the '$tenant' tenant."
    echo "(Suggestion: check username, password, tenant identifier, host and port.)"
    rm $READ_LIST_TMPFILE
    continue
  fi
  
  # Check for the presence of at least one list item in the results returned
  at_least_one_record_exists=0
  for results_item in ${read_list_results[*]}
  do
    if [[ $results_item =~ $LIST_ITEM_REGEX ]]; then
      at_least_one_record_exists=1
      break
    fi
  done

  # If there is at least one matching report record already present in
  # this tenant, don't create a new record, and move on to the next tenant
  if [ $at_least_one_record_exists == 1 ]; then
    echo "Found an Acquisition Summary report record in the '$tenant' tenant."
    echo "Will NOT create a new record."
    continue
  fi
  
  # Otherwise, create the new report record
  
  echo "Creating a new Acquisition Summary report record in the '$tenant' tenant ..."
  
  # As an admin user within this tenant, create the report record, and save
  # the response to this create request to a temporary file
  
  CREATE_RECORD_TMPFILE=`mktemp -t ${tempfilename}.XXXXX` || exit 1

  # 'data @- << END_OF_PAYLOAD', below, reads the data that is to be sent in a POST
  # request from standard input. This data, in turn, is read from a 'here document'
  # directly inline within the script, ending with the last line prior to the
  # 'END_OF_PAYLOAD' line.
  
  $CURL_EXECUTABLE \
  --include \
  --silent \
  --user "${DEFAULT_ADMIN_ACCTS[TENANT_COUNTER]}:$DEFAULT_ADMIN_PASSWORD" \
  --header "Content-Type: application/xml" \
  --url http://$HOST:$PORT/cspace-services/reports \
  --data @- << END_OF_PAYLOAD
<?xml version="1.0" encoding="utf-8"?>
<document name="reports">
  <ns2:reports_common xmlns:ns2="http://collectionspace.org/services/report"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <supportsDocList>false</supportsDocList>
    <supportsNoContext>true</supportsNoContext>
    <outputMIME>application/pdf</outputMIME>
    <name>Acquisition Summary</name>
    <filename>acq_basic.jasper</filename>
    <supportsGroup>false</supportsGroup>
    <supportsSingleDoc>true</supportsSingleDoc>
    <notes>Just a few fields about a single acquisition</notes>
    <forDocTypes>
      <forDocType>Acquisition</forDocType>
    </forDocTypes>
  </ns2:reports_common>
</document>
END_OF_PAYLOAD
  > $CREATE_RECORD_TMPFILE

  # Read the response from that file
  create_record_results=( $( < $CREATE_RECORD_TMPFILE ) )
  rm $CREATE_RECORD_TMPFILE

  # Echo the response to the create request to the console
  for results_item in ${create_record_results[*]}
  do
    echo results_item
  done
  
  let TENANT_COUNTER++
  
done


