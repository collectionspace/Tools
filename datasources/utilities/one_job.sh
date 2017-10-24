##################################################################################
#
# CRON TABLE (crontab) for CSpace Solr ETL
#
##################################################################################
#
# run solr ETL (and other webapp and API monitoring)
#
# currently runs under pseudo user app_solr on cspace-prod and cspace-dev
#
# 1. run the 13 solr4 updates
# 2. monitor solr datastore contents (email contents)
# 3. export and mail BAMPFA view for Orlando
# 4. export and mail Piction view for MCQ
#
##################################################################################
echo 'starting solr refreshes' `date`
/home/app_solr/solrdatasources/bampfa/solrETL-internal.sh         bampfa     >> /home/app_solr/solrdatasources/bampfa/solr_extract_internal.log  2>&1
/home/app_solr/solrdatasources/bampfa/solrETL-public.sh           bampfa     >> /home/app_solr/solrdatasources/bampfa/solr_extract_public.log  2>&1
/home/app_solr/solrdatasources/bampfa/bampfa_collectionitems_vw.sh bampfa    >> /home/app_solr/solrdatasources/bampfa/solr_extract_BAM.log  2>&1
/home/app_solr/solrdatasources/bampfa/piction_extract.sh          bampfa     >> /home/app_solr/solrdatasources/bampfa/solr_extract_Piction.log  2>&1

/home/app_solr/solrdatasources/botgarden/solrETL-public.sh        botgarden  >> /home/app_solr/solrdatasources/botgarden/solr_extract_public.log  2>&1
/home/app_solr/solrdatasources/botgarden/solrETL-internal.sh      botgarden  >> /home/app_solr/solrdatasources/botgarden/solr_extract_internal.log  2>&1
/home/app_solr/solrdatasources/botgarden/solrETL-propagations.sh  botgarden  >> /home/app_solr/solrdatasources/botgarden/solr_extract_propagations.log  2>&1

/home/app_solr/solrdatasources/pahma/solrETL-public.sh            pahma      >> /home/app_solr/solrdatasources/pahma/solr_extract_public.log  2>&1
/home/app_solr/solrdatasources/pahma/solrETL-internal.sh          pahma      >> /home/app_solr/solrdatasources/pahma/solr_extract_internal.log  2>&1
/home/app_solr/solrdatasources/pahma/solrETL-locations.sh         pahma      >> /home/app_solr/solrdatasources/pahma/solr_extract_locations.log  2>&1
/home/app_solr/solrdatasources/pahma/solrETL-osteology.sh         pahma      >> /home/app_solr/solrdatasources/pahma/solr_extract_osteology.log  2>&1

/home/app_solr/solrdatasources/ucjeps/solrETL-public.sh           ucjeps     >> /home/app_solr/solrdatasources/ucjeps/solr_extract_public.log  2>&1
/home/app_solr/solrdatasources/ucjeps/solrETL-media.sh            ucjeps     >> /home/app_solr/solrdatasources/ucjeps/solr_extract_media.log  2>&1
##################################################################################
# optimize all solrcores after refresh
##################################################################################
/home/app_solr/optimize.sh > /home/app_solr/optimize.log
##################################################################################
# monitor solr datastores
##################################################################################
if [[ `/home/app_solr/checkstatus.sh` ]] ; then /home/app_solr/checkstatus.sh -v | mail -s "PROBLEM with solr refresh nightly refresh" -- jblowe@berkeley.edu ; fi
/home/app_solr/checkstatus.sh -v
echo 'done with solr refreshes' `date`
