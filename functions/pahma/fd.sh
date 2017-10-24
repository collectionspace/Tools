time psql -t -U reporter -d "host=pahma.cspace.berkeley.edu dbname=nuxeo password=csR2p4rt2r" -f finddiffs.sql | mail -s "computed vs actual locations" mtblack@berkeley.edu
