#!/usr/bin/env /usr/bin/python

import cgi
import sys
import csv
import SysInvDB
from SysInvUtils import getConfig

def sendfile(l1,l2):

    config = getConfig('keyinfoProd.cfg')
    locations = SysInvDB.getloclist('range',l1,l2,1000,config)
    writer = csv.writer(sys.stdout) 
    rows = SysInvDB.getlocations(l1,l2,len(locations),config,'keyinfo')
    for r in rows:
        writer.writerow([r[i] for i in [0,2,3,4,5,6,7]])
   
print 'Content-type: application/octet-stream; charset=utf-8' 
print 'Content-Disposition: attachment; filename="mytest.xls"'
print
sendfile('Kroeber, 20A, AA  1,  1','Kroeber, 20A, AA  1,  2')
sys.stdout.flush()

