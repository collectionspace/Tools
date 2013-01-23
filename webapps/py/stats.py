#!/usr/bin/env /usr/bin/python

import random

def progress(location):

    counts = []
    cumulative = 0
    for d in range(1,12):
        query = "something like: select count(*) from table where location = '%s' and date = '2012-%02d'" % (location,d)
        #execute(query)
        result = int(random.random()*100) # get resulting number
        cumulative += result # let's make the number keep going up!
        counts.append(str(cumulative))
    return counts

if __name__ == "__main__":

    print "Content-type: text/html; charset=utf-8\n\n\n<html>"
    print "<h1>PAHMA Progress</h1>"

    print "<hr/><li>auto-scaling<li>12 random increasing values<li>no x axis labels<hr/>"
    # locations to generate pseudo-stats for
    locations = ['kroeber','regatta']
    counts = [0,0]
    for i,loc in enumerate(locations):
        # the progress function generates 12 randomly ascending values
        counts[i] = progress(loc)
        print loc,': ',' '.join(counts[i]),'<hr/>'
    
    # chart designed at https://developers.google.com/chart/image/docs/chart_wizard
    print '''<img src="//chart.googleapis.com/chart?chxt=y&chs=300x220&cht=lc&chco=FF0000,008000&chd=t:%s|%s&chdl=kroeber|regatta&&chds=a&chls=1|1" width="300" height="220" alt="" />''' % (','.join(counts[0]),','.join(counts[1]))
    print "<html>"

