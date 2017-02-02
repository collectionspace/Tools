The code in this directory extracts data from PAHMA CSpace into csv files.

It was originally intended to provision the Delphi system, and the query exracts fields used by that system.

However, it is currently used to provision the Solr4 datasources used by PAHMA (and other UCB deployments)

To run the ad hoc ETL  used in the pahma solr datasource, do something like the following in this directory:

$ ./solrETL-public.sh pahma

or, via crontab, something like the following (assumes the job is running under user apache):

[jblowe@ucjeps ~]$ sudo crontab -u apache -l
0 2 * * * /home/developers/pahma/solrETL-public.sh ucjeps >> /home/developers/pahma/solrExtract.log  2>&1

The script does the following:

* Extracts via sql the metadata needed for each object
* It does this incrementally via a set of sql query which are stitched together by join.py
* The various parts are merged into a single metadata file containing multi-valued fields, latlongs, etc.
* Extracts via sql the media (blob) metadata needed for each object
* Merges the two (i.e. adds the blob csid as a multivalued field to the metadata file)
* Clears out the pahma-public solr4 core
* Loads the merged .csv file into solr.

The script currently take about 20 minutes to run.

Caveats:

- the query, its results, and the resulting solr datasource are largely unverified. Caveat utilizator.
- the script assumes that the password for the reader user is in .pgpass; add it to the connect string in
  the script if it isn't.

(jbl 06/15/2014; 05/10/2015)
