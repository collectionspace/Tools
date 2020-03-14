#!/bin/bash
#
# Install sample reports on the nightly dev servers.
#

TENANTS+=('core' 'lhmc' 'fcart' 'anthro' 'materials' 'bonsai' 'botgarden' 'herbarium' 'publicart')

for tenant in ${TENANTS[*]}
do
  ./scripts/install_report_records.sh "https://${tenant}.qa.collectionspace.org" "$tenant.collectionspace.org"
done
