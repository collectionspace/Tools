curl http://localhost:8983/solr/ucjeps-public/update --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'  
curl http://localhost:8983/solr/ucjeps-public/update --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
