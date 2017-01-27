#!/bin/bash

####################################################
# Script for creating a batch record in multiple
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
TENANTS+=(core)

# Set space-separated lists of MIME types and their corresponding
# MIME type labels, below:
MIMETYPES+=(
    'application/pdf' )

MIMETYPE_LABELS+=(
    'PDF' )
	
# Name shown in batch output
BATCHXML_NAME="$1"
# Notes for the batch
BATCHXML_NOTES="$2"
# Document type for the batch
BATCHXML_DOCTYPE="$3"
# Supports no context
BATCHXML_SUPPORTS_NO_CONTEXT="$4"
# Supports single document?
BATCHXML_SUPPORTS_SINGLE_DOC="$5"
# Create a new focus (?)
BATCHXML_CREATES_NEW_FOCUS="$6"
# Java classname for the actual batch code
BATCHXML_CLASSNAME="$7"

BATCH_NAME_REGEX="(PDF)"

    
# Each item in each of the two lists above should correspond 1:1 with
# its counterpart in the other list. (Associative/hash-style arrays would
# make this simpler, but those are only implemented in very recent 'bash' versions.)

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
let ACCT_COUNTER=1
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

# FIXME: It may be prudent to add code to verify that any '401'
# response lines, not followed by 'Unauthorized', are truly
# response codes and not random occurrences of that number.
AUTHENTICATION_FAILURE_REGEX="^401 Unauthorized|^401"

# FIXME: It may be prudent to add code to verify that any '40x' or '50x'
# response lines are truly response codes and not random occurrences of that number.
POST_FAILURE_REGEX="^40[0-9]|^50[0-9]"

declare -i WARNINGS_COUNTER=0
declare -a WARNINGS_MSGS

declare -i ERRORS_COUNTER=0
declare -a ERRORS_MSGS

declare -i TENANT_COUNTER=0
for tenant in ${TENANTS[*]}
do

  let TENANT_COUNTER++

  tempfilename=`basename $0`
  # Three or more 'X's may be required in the template for the
  # temporary file name, under at least one or more Linux OSes
  READ_LIST_TMPFILE=`mktemp -t ${tempfilename}.XXXXX` || exit 1

  # As an admin user within this tenant, perform field-level search on the batch name
  # to find all existing records, if any, referring to this batch
  
  echo "Checking for an $BATCHXML_NAME batch record in the '$tenant' tenant ..."

  $CURL_EXECUTABLE \
  --get \
  --include \
  --silent \
  --show-error \
  --user "${DEFAULT_ADMIN_ACCTS[TENANT_COUNTER]}:$DEFAULT_ADMIN_PASSWORD" \
  --url http://$HOST:$PORT/cspace-services/batch \
  --data-urlencode "as=batch_common:name ILIKE '$BATCHXML_NAME%'" \
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
    msg="ERROR: Failed to authenticate successfully to the '$tenant' tenant."
	ERRORS_MSGS[$ERRORS_COUNTER]="$msg"
	ERRORS_COUNTER+=1
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

  # If there is at least one matching batch record already present in
  # this tenant, don't create a new record, and move on to the next tenant
  at_least_one_matching_batch_record_exists=0
  if [ $at_least_one_record_exists == 1 ]; then
      for results_item in ${read_list_results[*]}
      do
        if [[ $results_item =~ $BATCH_NAME_REGEX ]]; then
          at_least_one_matching_batch_record_exists=1
          break
        fi
      done
  fi
  if [ $at_least_one_matching_batch_record_exists == 1 ]; then
	echo
    msg="WARNING: Found an existing '$BATCHXML_NAME' batch record in the '$tenant' tenant.  No new record created."
	WARNINGS_MSGS[$WARNINGS_COUNTER]="$msg"
	WARNINGS_COUNTER+=1
    continue
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
  #		<supportsSingleDoc>true</supportsSingleDoc>
  #		<createsNewFocus>true</createsNewFocus>
  #		<className>org.collectionspace.services.batch.nuxeo.UpdateObjectLocationBatchJob</className>
  #	</ns2:batch_common>
  #</document>

  # Otherwise, create the new batch records
  #
  # As an admin user within this tenant, create batch records specifying
  # output should be created in each of a number of different MIME types,
  # and save the responses to these create requests to temporary files
  
  let MIMETYPE_COUNTER=0
  for mimetype in ${MIMETYPES[*]}
  do
	QUALIFIED_BATCHXML_NAME="$BATCHXML_NAME (${MIMETYPE_LABELS[MIMETYPE_COUNTER]})"
	MIMETYPE=${MIMETYPES[MIMETYPE_COUNTER]}
	echo
    echo "Creating a new '$QUALIFIED_BATCHXML_NAME' batch record for MIME type '$MIMETYPE' in the '$tenant' tenant..."
	
	PAYLOAD=`mktemp -t ${tempfilename}.XXXXX` || exit 1	
	echo XML Payload is: $PAYLOAD
	echo \
"<?xml version=\"1.0\" encoding=\"utf-8\"?>
<document name=\"batch\">
  <ns2:batch_common xmlns:ns2=\"http://collectionspace.org/services/batch\"
  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">
    <name>$QUALIFIED_BATCHXML_NAME</name>
    <notes>$BATCHXML_NOTES</notes>
    <forDocTypes>
      <forDocType>$BATCHXML_DOCTYPE</forDocType>
    </forDocTypes>
    <supportsNoContext>$BATCHXML_SUPPORTS_NO_CONTEXT</supportsNoContext>
    <supportsSingleDoc>$BATCHXML_SUPPORTS_SINGLE_DOC</supportsSingleDoc>
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
    --user "${DEFAULT_ADMIN_ACCTS[TENANT_COUNTER]}:$DEFAULT_ADMIN_PASSWORD" \
    --header "Content-Type: application/xml" \
    --url http://$HOST:$PORT/cspace-services/batch \
    --data @$PAYLOAD > $CREATE_RECORD_TMPFILE

	let MIMETYPE_COUNTER++
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
  	  msg="ERROR: Failed to successfully create the batch '$QUALIFIED_BATCHXML_NAME' to the '$tenant' tenant."
  	  ERRORS_MSGS[$ERRORS_COUNTER]="$msg"
	  ERRORS_COUNTER+=1
	  continue
    fi
	    
    # Help probabilistically ensure that batch are listed
    # in reverse order of creation - in list results and in
    # the UI's 'run rports dropdown menu - by waiting at least
    # 1 second before creating each batch
    sleep 1s
        
  done # End of per-MIME type 'do' loop
    
done # End of per-tenant 'do' loop

if [ $WARNINGS_COUNTER -gt 0 ]; then
	echo
	echo "### Warnings Summary: $WARNINGS_COUNTER warning(s)."
	declare -i count=0
	while [ $count -lt $WARNINGS_COUNTER ]
	do
		echo ${WARNINGS_MSGS[count]} >&2
		count+=1
	done
	exit 0
fi

if [ $ERRORS_COUNTER -gt 0 ]; then
	echo
	echo "### Errors Summary: $ERRORS_COUNTER error(s)."
	declare -i count=0
	while [ $count -lt $ERRORS_COUNTER ]
	do
		echo ${ERRORS_MSGS[count]} >&2
		count+=1
	done
	exit 1
fi
