__author__ = 'remillet'

from os import path
from django.contrib.auth.models import User
from common import cspace

HTTP_PROTOCOL = "http"
CSPACE_AUTHN_CONFIG_FILENAME = 'authn'

AUTHN_CONNECT = 'connect'  # The [connect] section of the config file
AUTHN_INFO = 'info'  # The [info] section of the config file
CSPACE_AUTHN_OVERRIDE_PROPERTY = 'override'

CSPACE_AUTHN_REALM_PROPERTY = 'realm'
CSPACE_AUTHN_URI_PROPERTY = 'uri'
CSPACE_AUTHN_HOSTNAME_PROPERTY = 'hostname'
CSPACE_AUTHN_PROTOCOL_PROPERTY = 'protocol'
CSPACE_AUTHN_PORT_PROPERTY = 'port'


def getConfigOption(config, property_name):
    """
    """
    return cspace.getConfigOptionWithSection(config, AUTHN_CONNECT, property_name)


class CSpaceAuthN(object):
    overrideWithConfig = False
    configFileExists = False
    realm = None
    uri = None
    hostname = None
    protocol = None
    port = None
    authNDictionary = dict()  # a transient map of cspace username/password tuples (not persisted)

    def isInitialzed(self):
        """
            This method tests to see if the required fields are all set.
        :type self: CSpaceAuthN
        :return:
        """
        result = True
        isMissingProperties = False
        errMsg = "The property/option %s must be set to a valid value."

        if self.realm is None:
            isMissingProperties = True
            print errMsg % CSPACE_AUTHN_REALM_PROPERTY
        if self.uri is None:
            isMissingProperties = True
            print errMsg % CSPACE_AUTHN_URI_PROPERTY
        if self.hostname is None:
            isMissingProperties = True
            print errMsg % CSPACE_AUTHN_HOSTNAME_PROPERTY
        if self.protocol is None:
            isMissingProperties = True
            print errMsg % CSPACE_AUTHN_PROTOCOL_PROPERTY
        if self.port is None:
            isMissingProperties = True
            print errMsg % CSPACE_AUTHN_PORT_PROPERTY

        if isMissingProperties is True:
            result = False

        return result

    def __init__(self):
        """
            This constructor will look for a config file named authn.cfg that must be a directory sibling of this class
            file.  If the class static property members have not already been set by the class method initialize()
            or the 'override' property is True then the values in the config file will be used.
        """

        try:
            config = cspace.getConfig(path.dirname(__file__), CSPACE_AUTHN_CONFIG_FILENAME)
            if cspace.getConfigOptionWithSection(config, AUTHN_INFO, CSPACE_AUTHN_OVERRIDE_PROPERTY) == "True":
                self.overrideWithConfig = True

            if self.__class__.realm is None or self.overrideWithConfig:
                self.__class__.realm = getConfigOption(config, CSPACE_AUTHN_REALM_PROPERTY)
            if self.__class__.uri is None or self.overrideWithConfig:
                self.__class__.uri = getConfigOption(config, CSPACE_AUTHN_URI_PROPERTY)
            if self.__class__.hostname is None or self.overrideWithConfig:
                self.__class__.hostname = getConfigOption(config, CSPACE_AUTHN_HOSTNAME_PROPERTY)
            if self.__class__.protocol is None or self.overrideWithConfig:
                self.__class__.protocol = getConfigOption(config, CSPACE_AUTHN_PROTOCOL_PROPERTY)
            if self.__class__.port is None or self.overrideWithConfig:
                self.__class__.port = getConfigOption(config, CSPACE_AUTHN_PORT_PROPERTY)

            self.configFileExists = True
        except Exception, e:
            self.configFileExists = False
            print "Warning: The CSpaceAuthN authenticate back-end config file %s was missing." % \
                  CSPACE_AUTHN_CONFIG_FILENAME + cspace.CONFIG_SUFFIX

        if self.isInitialzed() == False:
            errMsg = "The CSpaceAuthN Django authentication back-end was not properly initialized.  \
            Please check the log files for details."
            raise Exception(errMsg)

    @classmethod
    def initialize(cls, realm=None, uri=None, hostname=None, protocol=HTTP_PROTOCOL, port=None):
        """
            Some of the required properties may have already been set in the constructor.  We need to make this a class
            method (see @classmethod annotation) so we can call it from our Django application code -this is our only
            way to override the config file values.
        """
        if realm is not None:
            cls.realm = realm
        if uri is not None:
            cls.uri = uri
        if hostname is not None:
            cls.hostname = hostname
        if protocol is not None:
            cls.protocol = protocol
        if port is not None:
            cls.port = port

    # def make_get_request(self, realm, uri, hostname, protocol, port, username, password):
    #     """
    #         Makes HTTP GET request to a URL using the supplied username and password credentials.
    #     :rtype : a 3-tuple of the target URL, the data of the response, and an error code
    #     :param realm:
    #     :param uri:
    #     :param hostname:
    #     :param protocol:
    #     :param port:
    #     :param username:
    #     :param password:
    #     """
    #
    #     server = protocol + "://" + hostname + ":" + port
    #     passMgr = urllib2.HTTPPasswordMgr()
    #     passMgr.add_password(realm, server, username, password)
    #     authhandler = urllib2.HTTPBasicAuthHandler(passMgr)
    #     opener = urllib2.build_opener(authhandler)
    #     urllib2.install_opener(opener)
    #     url = "%s/%s" % (server, uri)
    #
    #     try:
    #         f = urllib2.urlopen(url)
    #         statusCode = f.getcode()
    #         data = f.read()
    #         result = (url, data, statusCode)
    #     except urllib2.HTTPError, e:
    #         print 'The server couldn\'t fulfill the request.'
    #         print 'Error code: ', e.code
    #         result = (url, None, e.code)
    #     except urllib2.URLError, e:
    #         print 'We failed to reach a server.'
    #         print 'Reason: ', e.reason
    #         result = (url, None, e.reason)
    #
    #     return result

    def authenticateWithCSpace(self, username=None, password=None):
        """
            Attempts to authenticate with a CollectionSpace Services instance.  Reads the URI, Realm, hostname from a
            config file name authn.cfg
        :param username:
        :param password:
        """
        result = False

        (url, data, statusCode) = cspace.make_get_request(self.realm, self.uri, self.hostname, self.protocol, self.port,
                                                        username, password)
        print "Request to %s: %s" % (url, statusCode)
        if statusCode is 200:
            result = True

        return result

    #
    # Django AuthN/AuthZ methods to implement.
    #

    def authenticate(self, username=None, password=None):
        """
            Called by Django's AuthN/AuthZ framework to authenticate a user with username and password credentials.
            This method attempts to authenticate with the specified CollectionSpace Services instance.  If authenti-
            cation is successful then the cspace user is added to Django's built-in User list with *no* password.  The
            cspace password is simply cached in this classes (CSpaceAuthN) 'authNDictionary' dictionary.

            *** NOTE *** If the cspace user's password changes in the back-end (in the CollectionSpace system) then any
            attempt by the application to use the cached password to connect to the back-end will fail until the user
            logs out and logs back in with the updated/correct password.
        """
        if self.isInitialzed() is False:
            raise Exception("The CSpaceAuthN authentication provider was not initialized properly.  \
            Please check the log files for details.")

        result = None
        # Check the username/password and return a User.
        authenticatedWithCSpace = self.authenticateWithCSpace(username=username, password=password)
        if authenticatedWithCSpace is True:
            try:
                result = User.objects.get(username=username)
            except User.DoesNotExist:
                newUser = User(username=username, password='none')
                newUser.is_staff = True
                newUser.is_superuser = True
                newUser.save()
                result = newUser

        if result is not None:
            result.cspace_password = password
            self.authNDictionary[username] = password

        return result

    def get_user(self, user_id):
        """
            Called by Django's AuthN/AuthZ framework to get the User instance from a user ID.

            *** NOTE *** If the cspace user's password changes in the back-end (in the CollectionSpace system) then any
            attempt by the application to use the cached password to connect to the back-end will fail until the user
            logs out and logs back in with the updated/correct password.
        """
        try:
            user = User.objects.get(pk=user_id)  # Lookup the user from Django's built-in list of users
            username = user.username
            passwd = self.authNDictionary[username]  # If they're a cspace user that's been authenticated, then we
            # should already have their password cached
            if passwd is not None:
                user.cspace_password = passwd  # Attach the user's cspace password to the User instance
            else:
                user = None  # If for some unknown reason the password is null, we should return the 'None'
        except User.DoesNotExist:
            user = None
        except IndexError:
            user = None
        except KeyError:
            user = None

        return user
