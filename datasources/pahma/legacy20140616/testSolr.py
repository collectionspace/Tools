import solr

# create a connection to a solr server
s = solr.SolrConnection('http://localhost:8983/solr/delphi1')

# do a search
response = s.query('description_txt:Mask')
for hit in response.results:
    print hit['objectnumber_s']
