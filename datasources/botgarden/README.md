this is the prototype solr4 datasource ETL for UCBG.

To run the ad hoc ETL  used in the botgarden solr datasource, do something like the following in this directory:

$ ./solrETL-public.sh botgarden

or, via crontab, something like the following (assumes the job is running under user apache):

[jblowe@ucjeps ~]$ sudo crontab -u apache -l
0 2 * * * /home/developers/botgarden/solrETL-public.sh botgarden >> /home/developers/botgarden/solrExtract.log  2>&1

It does the following:

* Extracts live and Dead accessions via two SQL queries.
* Massages the extract to make sure it will load into solr4
* Parses unparsed scientific names via a call to the the GBIF parser; pickles the results for subsequent use
* Loads it into the botgarden-public solr4 core, which is assumed to be up and available on localhost.


(jbl 05/10/2015)
