#!/bin/bash
#
# Install sample batch jobs on the nightly dev servers.
#

TENANTS+=('core' 'lhmc' 'fcart' 'anthro' 'materials' 'bonsai' 'botgarden' 'herbarium' 'publicart')

for tenant in ${TENANTS[*]}
do
  ./scripts/install_batch_records.sh "https://${tenant}.dev.collectionspace.org" "$tenant.collectionspace.org"
done
