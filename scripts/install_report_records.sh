#!/bin/bash
#
# This script requires 8 arguments to build a proper POST request to the
# CollectionSpace RESTFul API.
#
# The 'filename' argument (the 8th and last argument), needs to be the name of the
# JasperReports (http://community.jaspersoft.com) report file that is installed in
# the 'cspace/reports' directory of CollectionSpace.  For more information about CollectionSpace
# reports, visit this wiki page: https://wiki.collectionspace.org/display/DOC/How+to+add+and+run+reports
#
#<document name="reports">
#	<ns2:reports_common xmlns:ns2="http://collectionspace.org/services/report">
#		<name>The name of the report shown in the UI</name>		# 1st argument
#		<notes>Just a few fields about the report</notes>		# 2nd argument
#		<forDocTypes>
#			<forDocType>Acquisition</forDocType>				# 3rd argument
#		</forDocTypes>
#		<supportsSingleDoc>true</supportsSingleDoc>				# 4th argument
#		<supportsDocList>false</supportsDocList>				# 5th argument
#		<supportsGroup>false</supportsGroup>					# 6th argument
#		<supportsNoContext>true</supportsNoContext>				# 7th argument
#		<filename>acq_basic.jrxml</filename>					# 8th argument
#		<outputMIME>application/pdf</outputMIME>				# Gets filled out by 'create_report_records' invokation
#	</ns2:reports_common>
#</document>
#

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

CSPACE_URL="${1:-http://localhost:8180}"
TENANT="${2:-core.collectionspace.org}"

test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Acquisition Summary" "An acquisition summary report. Runs on a single record only." Acquisition true false false false application/pdf acq_basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Acquisition Basic List" "Catalog info for objects related to an acquisition record. Runs on a single record only." Acquisition true false false false application/pdf Acq_List_Basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Condition Check Basic List" "Catalog info for objects related to a condition check record. Runs on a single record only." Conditioncheck true false false false application/pdf CC_List_Basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Exhibition Basic List" "Catalog info for objects related to a exhibition record. Runs on a single record only." Exhibition true false false false application/pdf Exhibition_List_Basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Group Basic List" "Catalog info for objects related to a group record. Runs on a single record only." CollectionObject true true true false application/pdf Group_List_Basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Loan In Basic List" "Catalog info for objects related to a loan in record. Runs on a single record only." Loanin true false false false application/pdf LoansIn_List_Basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Loan Out Basic List" "Catalog info for objects related to a loan out record. Runs on a single record only." Loanout true false false false application/pdf LoansOut_List_Basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Acquisition Ethnographic Object List" "Core acquisition report. Runs on a single record only." Acquisition true false false false application/pdf coreAcquisition.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Group Object Ethnographic Object List" "Core group object report. Runs on a single record only." Group true false false false application/pdf coreGroupObject.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Intake Ethnographic Object List" "Core intake report. Runs on a single record only." Intake true false false false application/pdf coreIntake.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Loan In Ethnographic Object List" "Core loan in report. Runs on a single record only." Loanin true false false false application/pdf coreLoanIn.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Loan Out Ethnographic Object List" "Core loan out report. Runs on a single record only." Loanout true false false false application/pdf coreLoanOut.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Object Exit Ethnographic Object List" "Core object exit report. Runs on a single record only." ObjectExit true false false false application/pdf coreObjectExit.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Systematic Inventory" "Generate a checklist for performing an inventory on a range of storage locations. Runs on all records, using the provided start and end locations." Locationitem false false false true application/pdf systematicInventory.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Object Valuation" "Returns latest valuation information for selected objects. Runs in selected objects, or all objects." CollectionObject false true false true application/vnd.openxmlformats-officedocument.spreadsheetml.sheet object_valuation.jrxml

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
