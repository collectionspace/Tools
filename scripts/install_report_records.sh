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

test ./scripts/create-report-records.sh "Acquisition Summary" "An Acquisition Summary report" Acquisition true false false true acq_basic.jrxml
test ./scripts/create-report-records.sh "Acquisition Basic List" "Catalog info for objects related to an acquisition record" Acquisition true false false true Acq_List_Basic.jrxml
test ./scripts/create-report-records.sh "Condition Check Basic List" "Catalog info for objects related to a condition check record" Conditioncheck true false false true CC_List_Basic.jrxml
test ./scripts/create-report-records.sh "Exhibition Basic List" "Catalog info for objects related to a exhibition record" Exhibition true false false true Exhibition_List_Basic.jrxml
test ./scripts/create-report-records.sh "Group Basic List" "Catalog info for objects related to a group record" Group true false false true Group_List_Basic.jrxml
test ./scripts/create-report-records.sh "Loan-in Basic List" "Catalog info for objects related to a Loan-in record" Loanin true false false true LoansIn_List_Basic.jrxml
test ./scripts/create-report-records.sh "Loan-out Basic List" "Catalog info for objects related to a Loan-out record" Loanout true false false true LoansOut_List_Basic.jrxml
test ./scripts/create-report-records.sh "Acquisition Ethnographic Object List" "Core Acquisition Report" Acquisition true false false true coreAcquisition.jrxml 
test ./scripts/create-report-records.sh "Group Object Ethnographic Object List" "Core Group Object Report" Group true false true true coreGroupObject.jrxml
test ./scripts/create-report-records.sh "Intake Ethnographic Object List" "Core Intake Report" Intake true false false true coreIntake.jrxml
test ./scripts/create-report-records.sh "Loan In Ethnographic Object List" "Core Loan In Report" Loanin true false false true coreLoanIn.jrxml
test ./scripts/create-report-records.sh "Loan Out Ethnographic Object List" "Core Loan Out Report" Loanout true false false true coreLoanOut.jrxml
test ./scripts/create-report-records.sh "Object Exit Ethnographic Object List" "Core Object Exit Report" ObjectExit true false false true coreObjectExit.jrxml


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
