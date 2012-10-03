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

let TENANT_COUNTER=0
for tenant in ${TENANTS[*]}
do

  tempfilename=`basename $0`
  # Three or more 'X's may be required in the template for the
  # temporary file name, under at least one or more Linux OSes
  TMPFILE=`mktemp -t ${tempfilename}.XXXXX` || exit 1

  # As an admin user within this tenant, create the report
  # record, and save the response headers to a temporary file
  
  echo "Creating an Acquisition Summary report record in the '$tenant' tenant ..."
  
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
  > $TMPFILE

  # Read the response headers from that file
  results=( $( < $TMPFILE ) )
  
  for results_item in ${results[*]}
  do
    echo results_item
  done
  
  rm $TMPFILE
  
  let TENANT_COUNTER++
  
done


