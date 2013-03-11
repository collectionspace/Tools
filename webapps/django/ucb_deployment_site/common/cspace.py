__author__ = 'remillet'

import urllib2


def make_get_request(realm, uri, hostname, protocol, port, username, password):
    """
        Makes HTTP GET request to a URL using the supplied username and password credentials.
    :rtype : a 3-tuple of the target URL, the data of the response, and an error code
    :param realm:
    :param uri:
    :param hostname:
    :param protocol:
    :param port:
    :param username:
    :param password:
    """

    server = protocol + "://" + hostname + ":" + port
    passMgr = urllib2.HTTPPasswordMgr()
    passMgr.add_password(realm, server, username, password)
    authhandler = urllib2.HTTPBasicAuthHandler(passMgr)
    opener = urllib2.build_opener(authhandler)
    urllib2.install_opener(opener)
    url = "%s/%s" % (server, uri)

    try:
        f = urllib2.urlopen(url)
        statusCode = f.getcode()
        data = f.read()
        result = (url, data, statusCode)
    except urllib2.HTTPError, e:
        print 'The server couldn\'t fulfill the request.'
        print 'Error code: ', e.code
        result = (url, None, e.code)
    except urllib2.URLError, e:
        print 'We failed to reach a server.'
        print 'Reason: ', e.reason
        result = (url, None, e.reason)

    return result