#!/bin/bash
#
# Install sample batch jobs on the nightly dev servers.
#

TENANTS+=('outreach')

for tenant in ${TENANTS[*]}
do
  ./scripts/install_batch_records.sh "https://outreach.collectionspace.org" "$tenant.collectionspace.org"
done
