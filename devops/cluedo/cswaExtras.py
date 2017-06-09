#!/usr/bin/env /usr/bin/python
# -*- coding: UTF-8 -*-

import os
import sys
import ConfigParser

import time
import urllib2
import re
import base64
import psycopg2
import urllib2

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

def getConfig(fileName):
    try:
        config = ConfigParser.RawConfigParser()
        config.read(fileName)
        # test to see if it seems like it is really a config file
        logo = config.get('info', 'institution')
        return config
    except:
        return False

def getCSID(argType, objectnumber, http_parms):

    asquery = '%s?as=%s_common%%3Aobjectnumber%%3D%%27%s%%27&wf_deleted=false&pgSz=%s' % ('collectionobjects', 'collectionobjects', objectnumber, 1)

    uri = "cspace-services/" + asquery
    (objecturl, objectrecord, elapsedtime) = make_get_request(http_parms.realm, uri, http_parms.server, http_parms.username, http_parms.password)

    if objectrecord is None:
        return None, 'Error: the search for objectnumber \'%s.\' failed.' % objectnumber
    objectrecordtree = etree.fromstring(objectrecord)
    objectcsid = objectrecordtree.find('.//csid')
    if objectcsid is None:
        return None, 'no CSID found in response XML.'
    return objectcsid.text, ''


def getCSIDfromDB(argType, arg, config):
    dbconn = psycopg2.connect(config.get('connect', 'connect_string'))
    objects = dbconn.cursor()
    objects.execute(timeoutcommand)

    if argType == 'objectnumber':
        query = """SELECT h.name from collectionobjects_common cc
JOIN hierarchy h on h.id=cc.id
JOIN misc on (cc.id = misc.id and misc.lifecyclestate <> 'deleted')
WHERE objectnumber = '%s'""" % arg
    elif argType == 'placeName':
        query = """SELECT h.name from places_common pc
JOIN hierarchy h on h.id=pc.id
JOIN misc on (pc.id = misc.id and misc.lifecyclestate <> 'deleted')
WHERE pc.refname ILIKE '%""" + arg + "%%'"

    objects.execute(query)
    return objects.fetchone()


def make_get_request(realm, uri, server, username, password):
    """
        Makes HTTP GET request to a URL using the supplied username and password credentials.
    :rtype : a 3-tuple of the target URL, the data of the response, and an error code
    :param realm:
    :param uri:
    :param hostname:
    :param protocol:
    :param port:
    :param tenant:
    :param username:
    :param password:
    """

    elapsedtime = time.time()
    # if port == '':
    #     server = protocol + "://" + hostname
    # else:
    #     server = protocol + "://" + hostname + ":" + port

    # this is a bit elaborate because otherwise
    # the urllib2 approach to basicauth is to first try the request without the credentials, get a 401
    # then retry the request with the credentials... who know why...
    passMgr = urllib2.HTTPPasswordMgr()
    passMgr.add_password(realm, server, username, password)
    authhandler = urllib2.HTTPBasicAuthHandler(passMgr)
    opener = urllib2.build_opener(authhandler)
    unencoded_credentials = "%s:%s" % (username, password)
    auth_value = 'Basic %s' % base64.b64encode(unencoded_credentials).strip()
    opener.addheaders = [('Authorization', auth_value)]
    urllib2.install_opener(opener)
    url = "%s/cspace-services/%s" % (server, uri)

    try:
        f = urllib2.urlopen(url)
        statusCode = f.getcode()
        data = f.read()
        result = (url, data, statusCode)
    except urllib2.HTTPError, e:
        print 'The server (%s) couldn\'t fulfill the request.' % server
        print 'Error code: ', e.code
        result = (url, None, e.code)
    except urllib2.URLError, e:
        print 'We failed to reach the server (%s).' % server
        print 'Reason: ', e.reason
        result = (url, None, e.reason)
    except:
        raise
    
    return result #+ ((time.time() - elapsedtime),)

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
        if request_type == "POST" or "PUT":
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
        

