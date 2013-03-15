__author__ = 'remillet'

from os import path
from django.contrib.auth.models import User
from common import cspace

HTTP_PROTOCOL = "http"
CSPACE_AUTHN_CONFIG_FILENAME = 'authn'

CONFIGSECTION_AUTHN_CONNECT = 'connect'  # The [connect] section of the config file
CONFIGSECTION_AUTHN_INFO = 'info'  # The [info] section of the config file
CSPACE_AUTHN_OVERRIDE_PROPERTY = 'override'


def getConfigOption(config, property_name):
    """
    """
    return cspace.getConfigOptionWithSection(config, CONFIGSECTION_AUTHN_CONNECT, property_name)


class CSpaceAuthN(object):
    handleAuthNRequest = None  # a callback method to the main site
    configFileUsed = False
    realm = None
    uri = None
    hostname = None
    protocol = None
    port = None
    authNDictionary = None

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
            print errMsg % cspace.CSPACE_REALM_PROPERTY
        if self.uri is None:
            isMissingProperties = True
            print errMsg % cspace.CSPACE_URI_PROPERTY
        if self.hostname is None:
            isMissingProperties = True
            print errMsg % cspace.CSPACE_HOSTNAME_PROPERTY
        if self.protocol is None:
            isMissingProperties = True
            print errMsg % cspace.CSPACE_PROTOCOL_PROPERTY
        if self.port is None:
            isMissingProperties = True
            print errMsg % cspace.CSPACE_PORT_PROPERTY
        if self.authNDictionary is None:
            isMissingProperties = True
            print errMsg % "CSpaceAuthN.authNDictionary"

        if isMissingProperties is True:
            result = False

        return result

    def __init__(self):
        """
            This constructor will look for a config file named authn.cfg that must be a directory sibling of this class
            file.  If the class static property members have not already been set by the class method initialize()
            or the 'override' property is True then the values in the config file will be used.
        """

        if self.isInitialzed() is True:
            return  # Already initialized and ready to go

        try:
            config = cspace.getConfig(path.dirname(__file__), CSPACE_AUTHN_CONFIG_FILENAME)
            if cspace.getConfigOptionWithSection(config, CONFIGSECTION_AUTHN_INFO, CSPACE_AUTHN_OVERRIDE_PROPERTY) == "True":
                overrideWithConfig = True
            cls = self.__class__
            if cls.realm is None or overrideWithConfig:
                cls.realm = getConfigOption(config, cspace.CSPACE_REALM_PROPERTY)
                cls.configFileUsed = True

            if cls.uri is None or overrideWithConfig:
                cls.uri = getConfigOption(config, cspace.CSPACE_URI_PROPERTY)
                cls.configFileUsed = True

            if cls.hostname is None or overrideWithConfig:
                cls.hostname = getConfigOption(config, cspace.CSPACE_HOSTNAME_PROPERTY)
                cls.configFileUsed = True

            if cls.protocol is None or overrideWithConfig:
                cls.protocol = getConfigOption(config, cspace.CSPACE_PROTOCOL_PROPERTY)
                cls.configFileUsed = True

            if cls.port is None or overrideWithConfig:
                cls.port = getConfigOption(config, cspace.CSPACE_PORT_PROPERTY)
                cls.configFileUsed = True

            if cls.authNDictionary is None or overrideWithConfig:
                cls.authNDictionary = dict()
                cls.configFileUsed = True

        except Exception, e:
            print "Warning: The CSpaceAuthN authenticate back-end config file %s was missing." % \
                  CSPACE_AUTHN_CONFIG_FILENAME + cspace.CONFIG_SUFFIX

        if self.isInitialzed() is False:
            errMsg = "The CSpaceAuthN Django authentication back-end was not properly initialized.  \
            Please check the log files for details."
            raise Exception(errMsg)

    @classmethod
    def initialize(cls, handleAuthNRequest, realm=None, uri=None, hostname=None, protocol=HTTP_PROTOCOL, port=None):
        """
            Some of the required properties may have already been set in the constructor.  We need to make this a class
            method (see @classmethod annotation) so we can call it from our Django application code -this is our only
            way to override the config file values.
        """
        cls.handleAuthNRequest = handleAuthNRequest
        cls.authNDictionary = dict()  # A dictionary of cached passwords

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


    def authenticateWithCSpace(self, username=None, password=None):
        """
            Attempts to authenticate with a CollectionSpace Services instance.  Reads the URI, Realm, hostname from a
            config file name authn.cfg
        :param username:
        :param password:
        """
        result = False

        if self.__class__.handleAuthNRequest is not None:
            self.__class__.handleAuthNRequest()  # Call back to our delegate before making the AuthN request
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
