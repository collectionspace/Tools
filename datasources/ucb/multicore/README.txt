This setup structure support multiple cores for the UCB deployments.

To run this configuration, start jetty in the example/ directory using:

java -Dsolr.solr.home=multicore -jar start.jar

For general examples on standard solr configuration, see the "solr" directory.

6 cores are currently implemented:

pahma-metadata
botgarden-metadata
botgarden-propagations
ucjeps-metadata
cinefiles-metadata*
bampfa-metadata*

* not in use

