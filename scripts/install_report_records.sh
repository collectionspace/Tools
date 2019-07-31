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
TENANT="${2:-core}"

test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Acquisition Summary" "An acquisition summary report" Acquisition true false false false acq_basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Acquisition Basic List" "Catalog info for objects related to an acquisition record" Acquisition true false false false Acq_List_Basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Condition Check Basic List" "Catalog info for objects related to a condition check record" Conditioncheck true false false false CC_List_Basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Exhibition Basic List" "Catalog info for objects related to a exhibition record" Exhibition true false false false Exhibition_List_Basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Group Basic List" "Catalog info for objects related to a group record" Group true false false false Group_List_Basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Loan In Basic List" "Catalog info for objects related to a loan in record" Loanin true false false false LoansIn_List_Basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Loan Out Basic List" "Catalog info for objects related to a loan out record" Loanout true false false false LoansOut_List_Basic.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Acquisition Ethnographic Object List" "Core acquisition report" Acquisition true false false false coreAcquisition.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Group Object Ethnographic Object List" "Core group object report" Group true false false false coreGroupObject.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Intake Ethnographic Object List" "Core intake report" Intake true false false false coreIntake.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Loan In Ethnographic Object List" "Core loan in report" Loanin true false false false coreLoanIn.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Loan Out Ethnographic Object List" "Core loan out report" Loanout true false false false coreLoanOut.jrxml
test ./scripts/create-report-records.sh "$CSPACE_URL" "$TENANT" "Object Exit Ethnographic Object List" "Core object exit report" ObjectExit true false false false coreObjectExit.jrxml

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
