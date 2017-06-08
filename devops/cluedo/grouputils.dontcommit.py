import time
import logging
import urllib2
from cspace_django_site.main import cspace_django_site
from common import cspace
from toolbox.cswaUtils import relationsPayload
from common.utils import doSearch, loginfo


# alas, there are many ways the XML parsing functionality might be installed.
# the following code attempts to find and import the best...
try:
    from xml.etree.ElementTree import tostring, parse, Element, fromstring

    print("running with xml.etree.ElementTree")
except ImportError:
    try:
        from lxml import etree

        print("running with lxml.etree")
    except ImportError:
        try:
            # normal cElementTree install
            import cElementTree as etree

            print("running with cElementTree")
        except ImportError:
            try:
                # normal ElementTree install
                import elementtree.ElementTree as etree

                print("running with ElementTree")
            except ImportError:
                print("Failed to import ElementTree from any known place")

# global variables (at least to this module...)
config = cspace_django_site.getConfig()

# Get an instance of a logger, log some startup info
logger = logging.getLogger(__name__)
logger.info('%s :: %s :: %s' % ('grouper startup', '-', '%s | %s' % ('', '')))


def add2group(groupcsid, list_of_objects, request):
    connection = cspace.connection.create_connection(config, request.user)
    uri = 'cspace-services/relations'

    if len(list_of_objects) == 0:
        return ['no objects added to the group.']

    messages = []

    for object in list_of_objects:
        # messages.append("posting group2obj to relations REST API...")

        # "urn:cspace:institution.cspace.berkeley.edu:group:id(%s)" % groupCSID
        groupElements = {}
        groupElements['objectDocumentType'] = 'CollectionObject'
        groupElements['subjectDocumentType'] = 'Group'
        groupElements['objectCsid'] = object
        groupElements['subjectCsid'] = groupcsid

        payload = relationsPayload(groupElements)
        (url, data, csid, elapsedtime) = connection.postxml(uri=uri, payload=payload, requesttype="POST")
        # elapsedtimetotal += elapsedtime
        # messages.append('got relation csid %s elapsedtime %s ' % (csid, elapsedtime))
        groupElements['group2objCSID'] = csid
        # messages.append("relations REST API post succeeded...")

        # reverse the roles
        # messages.append("posting obj2group to relations REST API...")
        temp = groupElements['objectCsid']
        groupElements['objectCsid'] = groupElements['subjectCsid']
        groupElements['subjectCsid'] = temp
        groupElements['objectDocumentType'] = 'Group'
        groupElements['subjectDocumentType'] = 'CollectionObject'
        payload = relationsPayload(groupElements)
        (url, data, csid, elapsedtime) = connection.postxml(uri=uri, payload=payload, requesttype="POST")
        # elapsedtimetotal += elapsedtime
        # messages.append('got relation csid %s elapsedtime %s ' % (csid, elapsedtime))
        groupElements['obj2groupCSID'] = csid
        # messages.append("relations REST API post succeeded...")

    messages.append('%s item(s) added to group' % len(list_of_objects))
    return messages


def create_group(grouptitle, request):
    payload = """
        <document name="groups">
            <ns2:groups_common xmlns:ns2="http://collectionspace.org/services/group" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <title>%s</title>
            </ns2:groups_common>
        </document>
        """ % grouptitle

    connection = cspace.connection.create_connection(config, request.user)
    (url, data, csid, elapsedtime) = connection.postxml(uri='cspace-services/groups', payload=payload, requesttype="POST")
    return csid


def getfromCSpace(uri, request):
    connection = cspace.connection.create_connection(config, request.user)
    url = "cspace-services/" + uri
    return connection.make_get_request(url)


def find_group(request, grouptitle, pgSz):

    # TIMESTAMP = time.strftime("%b %d %Y %H:%M:%S", time.localtime())

    asquery = '%s?as=%s_common%%3Atitle%%3D%%27%s%%27&wf_deleted=false&pgSz=%s' % ('groups', 'groups', grouptitle, pgSz)

    # Make authenticated connection to cspace server...
    (groupurl, grouprecord, dummy, elapsedtime) = getfromCSpace(asquery, request)
    if grouprecord is None:
        return(None, None, 0, [], 'Error: the search for group \'%s.\' failed.' % grouptitle)
    grouprecordtree = fromstring(grouprecord)
    groupcsid = grouprecordtree.find('.//csid')
    if groupcsid is None:
        return(None, None, 0, [], None)
    groupcsid = groupcsid.text

    uri = 'collectionobjects?rtObj=%s&pgSz=%s' % (groupcsid, pgSz)
    try:
        (groupurl, groupmembers, dummy, elapsedtime) = getfromCSpace(uri, request)
        groupmembers = fromstring(groupmembers)
        totalItems = groupmembers.find('.//totalItems')
        totalItems = int(totalItems.text)
        objectcsids = [e.text for e in groupmembers.findall('.//csid')]
    except urllib2.HTTPError, e:
        return (None, None, 0, [], 'Error: we could not make list of group members')

    return (grouptitle, groupcsid, totalItems, objectcsids, None)


def delete_from_group(groupcsid, list_of_objects, request):
    connection = cspace.connection.create_connection(config, request.user)

    if len(list_of_objects) == 0:
        return ['no objects deleted from the group.']

    relationcsids = find_group_relations(request, groupcsid)
    delrelations = []
    for r in relationcsids:
        keep = False
        for a in r:
            if a in list_of_objects and groupcsid in r: keep = True
        if keep:
            delrelations.append(r[0])

    messages = []

    for object in delrelations:
        # messages.append("deleting relation %s..." % object)
        uri = 'cspace-services/relations/%s' % object
        (url, data, csid, elapsedtime) = connection.postxml(uri=uri, payload='', requesttype="DELETE")

    messages.append('%s item(s) deleted from group' % len(list_of_objects))
    return messages


def find_group_relations(request, groupcsid):

    TIMESTAMP = time.strftime("%b %d %Y %H:%M:%S", time.localtime())

    relationcsids = []
    for qtype in 'obj sbj'.split(' '):
        relationsquery = 'relations?%s=%s&pgSz=1000' % (qtype, groupcsid)

        # Make authenticated connection to ucjeps.cspace...
        (groupurl, searchresult, dummy, elapsedtime) = getfromCSpace(relationsquery, request)
        if searchresult is None:
            return(None, None, 'Error: We could not find the groupcsid \'%s.\' Please try another.' % groupcsid)
        relationlist = fromstring(searchresult)

        relations = relationlist.findall('.//relation-list-item')
        if relations is not None:
            for r in relations:
                relationcsids.append([e.text for e in r.findall('.//csid')])

    return relationcsids

def setup_solr_search(queryterms, context, prmz, request):
    context['searchValues']['querystring'] = ' OR '.join(queryterms)
    context['searchValues']['url'] = ''
    context['searchValues']['maxresults'] = prmz.MAXRESULTS
    loginfo(logger, 'start grouper search', context, request)
    return doSearch(context, prmz, request)