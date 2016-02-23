#!/usr/bin/env bash
#
# fetch all the publicly available solr4 datasources
#
# no authentication required!
curl -O https://webapps.cspace.berkeley.edu/4solr.bampfa.public.csv.gz
curl -O https://webapps.cspace.berkeley.edu/4solr.botgarden.propagations.csv.gz
curl -O https://webapps.cspace.berkeley.edu/4solr.botgarden.public.csv.gz
curl -O https://webapps.cspace.berkeley.edu/4solr.pahma.locations.csv.gz
curl -O https://webapps.cspace.berkeley.edu/4solr.pahma.media.csv.gz
curl -O https://webapps.cspace.berkeley.edu/4solr.pahma.osteology.csv.gz
curl -O https://webapps.cspace.berkeley.edu/4solr.pahma.public.csv.gz
curl -O https://webapps.cspace.berkeley.edu/4solr.ucjeps.media.csv.gz
curl -O https://webapps.cspace.berkeley.edu/4solr.ucjeps.public.csv.gz
