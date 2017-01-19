#!/bin/bash
#
# This script requires 7 arguments to build a proper POST request to the
# CollectionSpace RESTFul API.
# 
# For more information about CollectionSpace
# batch processes, visit this wiki page: https://wiki.collectionspace.org/display/DOC/Batch+Job+Service+RESTful+APIs
#
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

NEWLINE=$'\n'
echo "$NEWLINE"

declare -i ERRORS_COUNTER=0
declare -a ERRORS_MSGS

function test {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
		msg=$"Error executing $@."
		ERRORS_MSGS[ERRORS_COUNTER]="$msg"
		ERRORS_COUNTER+=1		
    fi
    return $status
}

test ./scripts/create-batch-records.sh "Update locations" "Update cataloging items' current computed location." CollectionObject true true false org.collectionspace.services.batch.nuxeo.UpdateObjectLocationBatchJob

#curl -G -v http://localhost:8180/cspace-services/reports --data-urlencode "as=reports_common:name ILIKE 'Acquisition Summary%'" -u admin@core.collectionspace.org:Administrator

if [ $ERRORS_COUNTER -gt 0 ]; then
	echo
	echo "### Errors Summary: $ERRORS_COUNTER error(s)."
	declare -i count=0
	while [ $count -lt $ERRORS_COUNTER ]
	do
		echo ${ERRORS_MSGS[count]} >&2
		count+=1
	done
fi
