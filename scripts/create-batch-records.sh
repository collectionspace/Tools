#!/bin/bash

####################################################
# Script for creating a batch record via the
# CollectionSpace Services REST API.
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

CSPACE_URL="$1"
TENANT="$2"
# Name shown in batch output
BATCHXML_NAME="$3"
# Notes for the batch
BATCHXML_NOTES="$4"
# Document type for the batch
BATCHXML_DOCTYPE="$5"
# Supports
BATCHXML_SUPPORTS_SINGLE_DOC="$6"
# Supports
BATCHXML_SUPPORTS_DOC_LIST="$7"
# Supports
BATCHXML_SUPPORTS_GROUP="$8"
# Supports
BATCHXML_SUPPORTS_NO_CONTEXT="$9"
# Create a new focus (?)
BATCHXML_CREATES_NEW_FOCUS="${10}"
# Java classname for the actual batch code
BATCHXML_CLASSNAME="${11}"

# Each item in each of the two lists above should correspond 1:1 with
# its counterpart in the other list. (Associative/hash-style arrays would
# make this simpler, but those are only implemented in very recent 'bash' versions.)

# This script assumes that each tenant's default administrator
# username follows a consistent pattern:
#   admin@{tenantidentifier}.collectionspace.org
# and that the passwords for each such account are identical,
# as per the variable set below:
DEFAULT_ADMIN_PASSWORD=Administrator

####################################################
# End of variables to set
####################################################

DEFAULT_ADMIN_ACCT="admin@$TENANT"

CURL_EXECUTABLE=`which curl`
if [ "xCURL_EXECUTABLE" == "x" ]
  then
    echo "Could not find 'curl' application"
    exit 1
fi

LIST_ITEM_REGEX="list-item"

# FIXME: It may be prudent to add code to verify that any '401'
# response lines, not followed by 'Unauthorized', are truly
# response codes and not random occurrences of that number.
AUTHENTICATION_FAILURE_REGEX="^401 Unauthorized|^401"

# FIXME: It may be prudent to add code to verify that any '40x' or '50x'
# response lines are truly response codes and not random occurrences of that number.
POST_FAILURE_REGEX="^40[0-9]|^50[0-9]"

tempfilename=`basename $0`
# Three or more 'X's may be required in the template for the
# temporary file name, under at least one or more Linux OSes
READ_LIST_TMPFILE=`mktemp -t ${tempfilename}.XXXXX` || exit 1

# As an admin user within this tenant, perform field-level search on the batch name
# to find all existing records, if any, referring to this batch

echo "Checking for $BATCHXML_CLASSNAME batch record in the '$TENANT' tenant ..."

$CURL_EXECUTABLE \
--get \
--include \
--silent \
--show-error \
--user "$DEFAULT_ADMIN_ACCT:$DEFAULT_ADMIN_PASSWORD" \
--url $CSPACE_URL/cspace-services/batch \
--data-urlencode "as=batch_common:className = '$BATCHXML_CLASSNAME'" \
> $READ_LIST_TMPFILE

# Read the response from that file
read_list_results=( $( < $READ_LIST_TMPFILE ) )
rm $READ_LIST_TMPFILE

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
  echo "ERROR: Failed to authenticate to the '$TENANT' tenant."
  exit 1
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

if [ $at_least_one_record_exists == 1 ]; then
echo
  echo "WARNING: Found an existing '$BATCHXML_CLASSNAME' batch record in the '$TENANT' tenant.  No new record created."
  exit
fi

#
# An example XML payload
#

#<document name="batch">
#	<ns2:batch_common xmlns:ns2="http://collectionspace.org/services/batch">
#		<name>The name of the batch shown in the UI</name>
#		<notes>Just a few fields about the batch</notes>
#		<forDocTypes>
#			<forDocType>Acquisition</forDocType>
#		</forDocTypes>
#		<supportsNoContext>true</supportsNoContext>
#		<forSingleDoc>true</forSingleDoc>
#		<createsNewFocus>true</createsNewFocus>
#		<className>org.collectionspace.services.batch.nuxeo.UpdateObjectLocationBatchJob</className>
#	</ns2:batch_common>
#</document>

# Otherwise, create the new batch records
#
# As an admin user within this tenant, create batch records specifying
# output should be created in each of a number of different MIME types,
# and save the responses to these create requests to temporary files

echo "Creating a new '$BATCHXML_CLASSNAME' batch record in the '$TENANT' tenant..."

PAYLOAD=`mktemp -t ${tempfilename}.XXXXX` || exit 1
echo XML Payload is: $PAYLOAD
echo \
"<?xml version=\"1.0\" encoding=\"utf-8\"?>
<document name=\"batch\">
  <ns2:batch_common xmlns:ns2=\"http://collectionspace.org/services/batch\"
  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">
    <supportsDocList>$BATCHXML_SUPPORTS_DOC_LIST</supportsDocList>
    <supportsNoContext>$BATCHXML_SUPPORTS_NO_CONTEXT</supportsNoContext>
    <supportsGroup>$BATCHXML_SUPPORTS_GROUP</supportsGroup>
    <supportsSingleDoc>$BATCHXML_SUPPORTS_SINGLE_DOC</supportsSingleDoc>
    <name>$BATCHXML_NAME</name>
    <notes>$BATCHXML_NOTES</notes>
    <forDocTypes>
      <forDocType>$BATCHXML_DOCTYPE</forDocType>
    </forDocTypes>
    <createsNewFocus>$BATCHXML_CREATES_NEW_FOCUS</createsNewFocus>
    <className>$BATCHXML_CLASSNAME</className>
  </ns2:batch_common>
</document>"\
> $PAYLOAD

CREATE_RECORD_TMPFILE=`mktemp -t ${tempfilename}.XXXXX` || exit 1
echo "curl result file: $CREATE_RECORD_TMPFILE"

$CURL_EXECUTABLE \
--include \
--show-error \
--silent \
--user "$DEFAULT_ADMIN_ACCT:$DEFAULT_ADMIN_PASSWORD" \
--header "Content-Type: application/xml" \
--url $CSPACE_URL/cspace-services/batch \
--data @$PAYLOAD > $CREATE_RECORD_TMPFILE

# Read the response from that file
create_record_results=( $( < $CREATE_RECORD_TMPFILE ) )

# Check for possible failure
post_failure_flag=0
for results_item in ${create_record_results[*]}
do
if [[ $results_item =~ $POST_FAILURE_REGEX ]]; then
  echo "HTTP Status code was: $results_item."
  post_failure_flag=1
  break
fi
done

if [ $post_failure_flag == 1 ]; then
  echo "ERROR: Failed to successfully create the batch '$BATCHXML_CLASSNAME' to the '$TENANT' tenant."
  exit 1
fi
