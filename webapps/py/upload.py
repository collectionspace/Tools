#!/usr/bin/env /usr/bin/python

import sys, json, re
import cgi

form    = cgi.FieldStorage()

def upload():
    #for r in cursor.fetchall():
    #    result.append({'value' : r[0]})


    print 'Content-Type: application/json\n\n'
    print form

upload()
