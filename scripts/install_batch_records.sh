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

CSPACE_URL="${1:-http://localhost:8180}"
TENANT="${2:-core.collectionspace.org}"

DEFAULT_ADMIN_PASSWORD=Administrator
DEFAULT_ADMIN_ACCT="admin@$TENANT"

CURL_EXECUTABLE=`which curl`
if [ "xCURL_EXECUTABLE" == "x" ]
  then
    echo "Could not find 'curl' application"
    exit 1
fi

tempfilename=`basename $0`
# Three or more 'X's may be required in the template for the
# temporary file name, under at least one or more Linux OSes
READ_AUTHORITIES_TMPFILE=`mktemp -t ${tempfilename}.XXXXX` || exit 1

echo "Getting authority record types for the '$TENANT' tenant ..."

$CURL_EXECUTABLE \
--get \
--silent \
--show-error \
--user "$DEFAULT_ADMIN_ACCT:$DEFAULT_ADMIN_PASSWORD" \
--url $CSPACE_URL/cspace-services/servicegroups/authority \
> $READ_AUTHORITIES_TMPFILE

# Read the response from that file
authoritydoctypes=`xmllint --xpath "//hasDocType" $READ_AUTHORITIES_TMPFILE`
rm $READ_AUTHORITIES_TMPFILE

authoritydoctypes=${authoritydoctypes//<hasDocType>/}
authoritydoctypes=${authoritydoctypes//<\/hasDocType>/,}
authoritydoctypes=${authoritydoctypes%%,}

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

test ./scripts/create-batch-records.sh "$CSPACE_URL" "$TENANT" "Update Current Location" "Recompute the current location of Object records, based on the related Location/Movement/Inventory records. Runs on a single record or all records." CollectionObject true false false true false org.collectionspace.services.batch.nuxeo.UpdateObjectLocationBatchJob
test ./scripts/create-batch-records.sh "$CSPACE_URL" "$TENANT" "Update Inventory Status" "Set the inventory status of selected Object records. Runs on a record list only." CollectionObject false true false false false org.collectionspace.services.batch.nuxeo.UpdateInventoryStatusBatchJob
test ./scripts/create-batch-records.sh "$CSPACE_URL" "$TENANT" "Merge Authority Items" "Merge an authority item into a target, and update all referencing records. Runs on a single record only." $authoritydoctypes true false false false false org.collectionspace.services.batch.nuxeo.MergeAuthorityItemsBatchJob

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
