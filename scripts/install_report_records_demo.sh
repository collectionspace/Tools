#!/bin/bash
#
# Install sample reports on the demo servers.
#

TENANTS+=('core' 'lhmc' 'fcart' 'anthro' 'materials' 'bonsai' 'publicart')

for tenant in ${TENANTS[*]}
do
  ./scripts/install_report_records.sh "https://${tenant}.collectionspace.org" $tenant
done
