this is the prototype solr4 datasource ETL for BAMPFA.

It does the following:

* Extracts metadata and media CSIDs from CSpace
* Massages the extract to make sure it will load into solr4
* Loads it into the BAMPFA-public solr4 core, which is assumed to be up and available on localhost.

NB: the code for the nightly extract for the Drupal website (BAMPFA-351) is stored here, but does
not run under app_solr like the rest of the extracts: it runs under app_webapps since it has
to write its output to /var/www/static, which is owned by app_webapps.

Here's the bit of crontab that does this:

##################################################################################
# run the nightly bampfa extract for the drupal website
##################################################################################
01 05 * * * cd ~/extracts/bampfa ; /home/app_webapps/extracts/bampfa/bampfa_website_extract.sh bampfa
