#!/usr/bin/env /usr/bin/python

import cgi
import sys
import csv

def sendfile(file):

    #print '<h3>In progress!</h3>'
    #return 
    #logFile = config.get('files','logfileprefix') + '.' + datetime.datetime.utcnow().strftime("%Y%m%d%H%M%S") + myPid + '.csv'
    data = [ [1,2], [3,4], ['a','b'] ]
    try:
	writer = csv.writer(sys.stdout) 
	for item in data: 
	    writer.writerow(item)
    except:
	raise
        print 'log failed!'


print 'Content-type: application/octet-stream; charset=utf-8'
print 'Content-Disposition: attachment; filename="mytest.xls"'
print
sendfile('text')
sys.stdout.flush()

