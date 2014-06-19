#!/bin/bash -x
date
cd /home/developers/
rm -rf /home/developers/Tools
rm -rf /home/developers/ucjeps
git clone https://github.com/cspace-deployment/Tools.git
cp -r Tools/datasources/ucjeps/ ucjeps
cd ucjeps
# insert passwords
# vi makeCsv2.sh 
# extract and load ucjeps data into solr (takes 10 mins or so)
# time nohup ./makeCsv2.sh ucjeps &
# don't forget to make a cron job for this
# 0 3 * * * /home/developers/ucjeps/makeCsv2.sh ucjeps >> /home/developers/ucjeps/extract.log.txt
# or, if you can't get through to the host, load your convenient local copy...
# cd ~
# scp dev.cspace.berkeley.edu:/home/developers/ucjeps/4solr* .
# gunzip ~/4solr.ucjeps.metadata.csv.gz 
# time curl 'http://localhost:8983/solr/ucjeps-metadata/update/csv?commit=true&header=true&trim=true&separator=%7C&f.blobs_ss.split=true&f.blobs_ss.separator=,' --data-binary @4solr.ucjeps.metadata.csv -H 'Content-type:text/plain; charset=utf-8'
