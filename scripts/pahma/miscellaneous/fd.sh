time psql -t -U reporter -d "host=pahma.cspace.berkeley.edu dbname=nuxeo password=xxxxxxxx" -f finddiffs.sql | mail -s "computed vs actual locations" mtblack@berkeley.edu
