import solr

# create a connection to a solr server
s = solr.SolrConnection(url = 'http://localhost:8983/solr/metadata', http_user = 'guest', http_pass = '')

# do a search
response = s.query('description_txt:arrow', facet='true', facet_field=['medium_s','culture_s'], rows=20, facet_limit=20, facet_mincount=1)
for hit in response.results:
    print hit['objectnumber_s']
