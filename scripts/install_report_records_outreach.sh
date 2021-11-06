#!/bin/bash
#
# Install sample reports on the outreach server.
#

TENANTS+=('core')

for tenant in ${TENANTS[*]}
do
  ./scripts/install_report_records.sh "https://outreach.collectionspace.org" "$tenant.collectionspace.org"
done
