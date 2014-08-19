curl -u "admin@botgarden.cspace.berkeley.edu:bgNPtochange" -X POST "https://botgarden.cspace.berkeley.edu/cspace-services/reports/$1" -H "Content-Type:application/xml" -T payload.xml > $2
