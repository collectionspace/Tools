#!/usr/bin/env /usr/bin/python
# -*- coding: UTF-8 -*-

import os
import sys
import ConfigParser

import time
import urllib2
import re
import base64

reload(sys)
sys.setdefaultencoding('utf-8')

timeoutcommand = "set statement_timeout to 240000; SET NAMES 'utf8';"

MAXLOCATIONS = 1000

try:
    import xml.etree.ElementTree as etree
    #print("running with ElementTree")
except ImportError:
    try:
        from lxml import etree
        #print("running with lxml.etree")
    except ImportError:
        try:
            # normal cElementTree install
            import cElementTree as etree
            #print("running with cElementTree")
        except ImportError:
            try:
                # normal ElementTree install
                import elementtree.ElementTree as etree
                #print("running with ElementTree")
            except ImportError:
                print("Failed to import ElementTree from any known place")


def getConfig(form):
    try:
        fileName = form.get('webapp') + '.cfg'
        config = ConfigParser.RawConfigParser()
        config.read(fileName)
        # test to see if it seems like it is really a config file
        logo = config.get('info', 'logo')
        return config
    except:
        return False


def relationsPayload(f):
    payload = """<?xml version="1.0" encoding="UTF-8"?>
<document name="relations">
  <ns2:relations_common xmlns:ns2="http://collectionspace.org/services/relation" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <relationshipType>affects</relationshipType>
    <objectCsid>%s</objectCsid>
    <objectDocumentType>%s</objectDocumentType>
    <subjectCsid>%s</subjectCsid>
    <subjectDocumentType>%s</subjectDocumentType>
  </ns2:relations_common>
</document>
"""
    payload = payload % (f['objectCsid'], f['objectDocumentType'], f['subjectCsid'], f['subjectDocumentType'])
    return payload

def make_request(request_type, uri, realm, server, username, password, payload=None):
    # print ("THIS IS IT " , request_type, uri, realm, server, username, password)
    print (payload)
    
    passman = urllib2.HTTPPasswordMgr()
    passman.add_password(realm, server, username, password)
    authhandler = urllib2.HTTPBasicAuthHandler(passman)
    opener = urllib2.build_opener(authhandler)
    url = "%s/cspace-services/%s" % (server, uri)

    # Stuff only in the GET requests
    unencoded_credentials = "%s:%s" % (username, password)
    auth_value = 'Basic %s' % base64.b64encode(unencoded_credentials).strip()
    opener.addheaders = [('Authorization', auth_value)]

    urllib2.install_opener(opener)

    if request_type == "PUT" or request_type == "POST":
        request = urllib2.Request(url, payload, {'Content-Type': 'application/xml'})
        if request_type == 'PUT':
            request.get_method = lambda: 'PUT'
        else:
            request.get_method = lambda: 'POST'

    elif request_type == "GET":
        request = url 
    
    try:
        f = urllib2.urlopen(request)
        statusCode = f.getcode()
        data = f.read()
        info = f.info() 
        if request_type == "POST" or request_type == "PUT":
            if info.getheader('Location'):
                csid = re.search(uri + '/(.*)', info.getheader('Location'))
                csid = csid.group(1)
            else:
                csid = ""
            result = (url, data, csid)
        else:
            result = (url, data, statusCode)
    except urllib2.URLError, e:
        if hasattr(e, 'reason'):
            sys.stderr.write('We failed to reach a server.\n')
            sys.stderr.write('Reason: ' + str(e.reason) + '\n')
        if hasattr(e, 'code'):
            sys.stderr.write('The server couldn\'t fulfill the request.\n')
            sys.stderr.write('Error code: ' + str(e.code) + '\n')
        if True:
            sys.stderr.write('ERROR IN %s-ing' % request_type)
            raise 
    return result
        

