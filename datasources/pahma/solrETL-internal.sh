#!/bin/bash -x
#
##############################################################################
# this script loads the solr core for the "internal" portal.
#
# the input file is created by the script that creates the input file for
# the public core, so all this script has to do is unzip it and POST it to
# to the Solr update endpoint...
#
# Features of the 'internal' metadata, so far:
#
# un-obfuscated latlongs
# all images, "in the clear", including catalog cards
# museum location info
#
##############################################################################
date
cd /home/app_solr/solrdatasources/pahma
##############################################################################
# note that there are 4 nightly scripts, public, internal, and locations,
# and osteology.
# the scripts need to run in order: public > internal > locations | osteology.
# internal (this script) depends on data created by public
# so in this case, the internal script cannot 'stash' any files...they
# have already been stashed by the public script, and this script needs one
# of them.
# while most of this script is already tenant specific, many of the specific commands
# are shared between the different scripts; having them be as similar as possible
# eases maintenance. ergo, the TENANT parameter
##############################################################################
TENANT=$1
##############################################################################
# gunzip the csv file for the internal store, prepared by the solrETL-public.sh
##############################################################################
gunzip -f 4solr.$TENANT.internal.csv.gz
##############################################################################
# ok, now let's load this into solr...
# clear out the existing data
##############################################################################
curl -S -s "http://localhost:8983/solr/${TENANT}-internal/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/${TENANT}-internal/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
##############################################################################
# this POSTs the csv to the Solr / update endpoint
# note, among other things, the overriding of the encapsulator with \
##############################################################################
time curl -S -s "http://localhost:8983/solr/${TENANT}-internal/update/csv?commit=true&header=true&separator=%09&f.objpp_ss.split=true&f.objpp_ss.separator=%7C&f.anonymousdonor_ss.split=true&f.anonymousdonor_ss.separator=%7C&f.donor_ss.split=true&f.donor_ss.separator=%7C&f.objaltnum_ss.split=true&f.objaltnum_ss.separator=%7C&f.objfilecode_ss.split=true&f.objfilecode_ss.separator=%7C&f.objdimensions_ss.split=true&f.objdimensions_ss.separator=%7C&f.objmaterials_ss.split=true&f.objmaterials_ss.separator=%7C&f.objinscrtext_ss.split=true&f.objinscrtext_ss.separator=%7C&f.objcollector_ss.split=true&f.objcollector_ss.separator=%7C&f.objaccno_ss.split=true&f.objaccno_ss.separator=%7C&f.objaccdate_ss.split=true&f.objaccdate_ss.separator=%7C&f.objacqdate_ss.split=true&f.objacqdate_ss.separator=%7C&f.objassoccult_ss.split=true&f.objassoccult_ss.separator=%7C&f.objculturetree_ss.split=true&f.objculturetree_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,&f.card_ss.split=true&f.card_ss.separator=,&f.imagetype_ss.split=true&f.imagetype_ss.separator=,&encapsulator=\\" --data-binary @4solr.$TENANT.internal.csv -H 'Content-type:text/plain; charset=utf-8'
##############################################################################
# wrap things up: make a gzipped version of what was loaded
##############################################################################
gzip -f 4solr.*.csv
date
