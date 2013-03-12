__author__ = 'remillet'

from os import path
from ConfigParser import NoOptionError
import urllib2
import ConfigParser

CONFIG_SUFFIX = ".cfg"
AUTHN_CONNECT = 'connect'  # The [connect] section of the config file


def getConfig(base_path, filename_nosuffix):
    """
        Read in our config file.  Look for it to be a sibling of the current .py file (this authn.py file).
    :param filename_nosuffix:
    """
    fileName = filename_nosuffix + CONFIG_SUFFIX
    relative_path = path.join(base_path, fileName)  # config file should be one of our siblings
    config = ConfigParser.RawConfigParser()
    config.read(relative_path)
    theSections = config.sections()
    if len(theSections) is 0:
        errMsg = "Could not find the required config file %s" % relative_path
        print(errMsg)
        raise Exception(errMsg)

    return config


def getConfigOptionWithSection(config, section, property_name):
    result = None
    try:
        result = config.get(section, property_name)
    except NoOptionError:
        print "Found no option %s" % property_name

    return result



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