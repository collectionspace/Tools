#!/usr/bin/env /usr/bin/python

import sys, json, re
import cgi
import cgitb;

cgitb.enable()  # for troubleshooting
import pgdb

form = cgi.FieldStorage()

timeoutcommand = 'set statement_timeout to 500'

def makeTemplate(table,term,expression):
    return """select distinct(%s)
            FROM %s tg
            INNER JOIN hierarchy h_tg ON h_tg.id=tg.id
            INNER JOIN hierarchy h_loc ON h_loc.id=h_tg.parentid
            INNER JOIN misc ON misc.id=h_loc.id AND misc.lifecyclestate <> 'deleted'
            WHERE %s %s ORDER BY %s LIMIT 30;""" % (term,table,term,expression,term)
    
def dbtransaction(form):
    postgresdb = pgdb.connect(form.get('connect_string'))
    cursor = postgresdb.cursor()

    q = form.get("q")
    elementID = form.get("elementID")
    # elementID is of the form xx.csid, where xx is a 2-letter code and csid is the csid of the record
    # for which the sought value is relevant.
    srchindex = re.search(r'^(..)\.(.*)', elementID)
    srchindex = srchindex.group(1)
    if srchindex in ['lo']:
        srchindex = 'location'
    elif srchindex in ['gr']:
        srchindex = 'group'
    elif srchindex in ['cp']:
        srchindex = 'longplace'
    elif srchindex in ['ob']:
        srchindex = 'object'
    elif srchindex in ['pl']:
        srchindex = 'place'
    elif srchindex in ['ta']:
        srchindex = 'taxon'
    elif srchindex in ['cx']:
        srchindex = 'concept2'
    elif srchindex in ['fc']:
        srchindex = 'concept'
    elif srchindex in ['px']:
        srchindex = 'longplace2'
    else:
        srchindex = 'concept'

    try:
        if srchindex == 'location':
            #template = makeTemplate('loctermgroup', "termdisplayname,replace(termdisplayname,' ','0') locationkey","like '%s%%'")
            # location is special, since we need to make a sort key to defeat postgres' whitespace collation
            template = """select termdisplayname,replace(termdisplayname,' ','0') locationkey 
            FROM loctermgroup tg
            INNER JOIN hierarchy h_tg ON h_tg.id=tg.id
            INNER JOIN hierarchy h_loc ON h_loc.id=h_tg.parentid
            INNER JOIN misc ON misc.id=h_loc.id and misc.lifecyclestate <> 'deleted'
            WHERE termdisplayname like '%s%%' order by locationkey limit 30;"""
        elif srchindex == 'object':
            # objectnumber is special: not an authority, no need for joins
            template = "select distinct(objectnumber) FROM collectionobjects_common WHERE objectnumber like '%s%%' ORDER BY objectnumber LIMIT 30;"
        elif srchindex == 'group':
            template = makeTemplate('grouptermgroup', 'termdisplayname',"like '%s%%'")
        elif srchindex == 'place':
            template = makeTemplate('placetermgroup', 'termname',"ilike '%%%s%%' and termtype='descriptor'")
        elif srchindex == 'longplace':
            template = makeTemplate('placetermgroup', 'termdisplayname',"like '%s%%' and termtype='descriptor'")
        elif srchindex == 'concept':
            template = makeTemplate('concepttermgroup', 'termname',"ilike '%%%s%%' and termtype='descriptor'")
        elif srchindex == 'concept2':
            template = makeTemplate('concepttermgroup', 'termname',"ilike '%%%s%%'")
        elif srchindex == 'longplace2':
            template = makeTemplate('placetermgroup', 'termdisplayname',"like '%s%%'")
        elif srchindex == 'taxon':
            template = makeTemplate('taxontermgroup', 'termdisplayname',"like '%s%%'")

        #sys.stderr.write('template %s' % template)

        # double single quotes that appear in the data, to make psql happy
        q = q.replace("'","''")
        query = template % q
        #sys.stderr.write("autosuggest query: %s" % query)
        cursor.execute(query)
        result = []
        for r in cursor.fetchall():
            result.append({'value': r[0]})

        result.append({'s': srchindex})

        print 'Content-Type: application/json\n\n'
        #print 'debug autosuggest', srchindex,elementID
        print json.dumps(result)    # or "json.dump(result, sys.stdout)"

    except pgdb.DatabaseError, e:
        sys.stderr.write('autosuggest select error: %s' % e)
        return None
    except:
        sys.stderr.write("some other autosuggest database error!")
        return None


dbtransaction(form)
