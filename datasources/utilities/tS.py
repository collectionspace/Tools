import solr
import sys

try:
    core = sys.argv[1]
except:
    print "syntax: python %s solar_core" % sys.argv[0]
    print "e.g     python %s pahma-public" % sys.argv[0]
    sys.exit(1)

try:
    # create a connection to a solr server
    s = solr.SolrConnection(url = 'http://localhost:8983/solr/%s' % core, http_user = 'guest', http_pass = '')

    # do a search
    response = s.query('*:*', rows=20)
    print '%s, records found: %s' % (core,response._numFound)

    details = False

    if details:
        for hit in response.results:
            for h in hit:
                print hit[h],
            print
except:
    print "could not access %s." % core

