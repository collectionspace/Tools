#!/bin/bash
#
# Install sample reports on the demo servers.
#

TENANTS+=('core' 'lhmc' 'fcart' 'anthro' 'materials' 'bonsai' 'botgarden' 'herbarium' 'publicart')

for tenant in ${TENANTS[*]}
do
  ./scripts/install_report_records.sh "https://${tenant}.collectionspace.org" "$tenant.collectionspace.org"
done
