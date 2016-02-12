#!/bin/bash -x
# scps all the csv files for the UCB Solr4 deployments
# run this before you run loadAllDatasourcees.sh
#
# caution: downloads serveral GB of compressed files! And you need to have ssh access to the prod server.
scp cspace-prod.cspace.berkeley.edu:/tmp/4solr*.gz .
gunzip 4solr*.gz
