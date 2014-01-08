#!/bin/bash -x
date
cd /home/developers/
rm -rf /home/developers/Tools
rm -rf /home/developers/solr4
# install solr
wget http://archive.apache.org/dist/lucene/solr/4.4.0/solr-4.4.0.tgz
tar -xzvf solr-4.4.0.tgz 
mv solr-4.4.0 solr4
cd /home/developers/solr4/
# we use the example core as the basis for the ucjeps core
mv example/ ucjeps
cd ucjeps/
rm -rf exampledocs/
rm -rf example-DIH/
rm -rf example-schemaless/
cd solr
mv collection1/ ucjeps-metadata
cd /home/developers/solr4/ucjeps/solr/ucjeps-metadata/
# name the core 'ucjeps-metadata'
perl -i -pe 's/collection1/ucjeps-metadata/g' core.properties
# merge in the ucjeps specific stuff (schema, etc.)
cd /home/developers
git clone https://github.com/cspace-deployment/Tools.git
cp -r Tools/datasources/ucb/multicore/ucjeps/metadata/conf/* solr4/ucjeps/solr/ucjeps-metadata/conf/
cd /home/developers/solr4/ucjeps
# start single core solr instance (under jetty)
nohup java -Xmx512m -jar start.jar &
# it should have started solr, let's check...
echo waiting 10 seconds for solr to start...
sleep 10
ps aux | grep java
tail /home/developers/solr4/ucjeps/nohup.out
# don't forget to install solrpy -- python to solr bindings
# needs to be done by hand for now...
# sudo su -
# source /usr/local/share/django/venv26/bin/activate
# pip install solrpy

