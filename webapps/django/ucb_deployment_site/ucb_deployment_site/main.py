from os import path
from authn.authn import CSpaceAuthN
from common import cspace


class ucb_deployment_site:
    """

    """
    should_reload_config = False
    should_reload_authn_config = False
    is_initialized = False
    config = None

    @classmethod
    def loadConfig(cls):
        result = cspace.getConfig(path.dirname(__file__), "main")
        return result

    @classmethod
    def shouldInitialize(cls):
        result = False
        if ucb_deployment_site.is_initialized is False or ucb_deployment_site.should_reload_config is True:
            result = True
        return result

    @classmethod
    def handleAuthNRequest(cls):
        if cls.should_reload_authn_config:
            config = cls.loadConfig()
            cls.initialize_authn(config)


    @classmethod
    def initialize_authn(cls, config):
        #
        # Read the required params from the config file
        #
        realm = cspace.getConfigOptionWithSection(config,
                                                  cspace.CONFIGSECTION_AUTHN_CONNECT, cspace.CSPACE_REALM_PROPERTY)
        uri = cspace.getConfigOptionWithSection(config,
                                                cspace.CONFIGSECTION_AUTHN_CONNECT, cspace.CSPACE_URI_PROPERTY)
        hostname = cspace.getConfigOptionWithSection(config,
                                                     cspace.CONFIGSECTION_AUTHN_CONNECT, cspace.CSPACE_HOSTNAME_PROPERTY)
        protocol = cspace.getConfigOptionWithSection(config,
                                                     cspace.CONFIGSECTION_AUTHN_CONNECT, cspace.CSPACE_PROTOCOL_PROPERTY)
        port = cspace.getConfigOptionWithSection(config,
                                                 cspace.CONFIGSECTION_AUTHN_CONNECT, cspace.CSPACE_PORT_PROPERTY)
        #
        #  def initialize(realm=None, uri=None, hostname=None, protocol=HTTP_PROTOCOL, port=None):
        #
        CSpaceAuthN.initialize(cls.handleAuthNRequest, realm, uri, hostname, protocol, port)


    @classmethod
    def initialize(cls):
        """
            Initializes our site.

        """
        if ucb_deployment_site.shouldInitialize() is False:
            print "Warning.  Reinitializing the site."

        cls.config = cls.loadConfig()
        cls.should_reload_config = cspace.getConfigOptionWithSection(cls.config, cspace.CONFIGSECTION_INFO,
                                                                     cspace.CSPACE_SHOULD_RELOAD_CONFIG)
        cls.should_reload_authn_config = cspace.getConfigOptionWithSection(cls.config, cspace.CONFIGSECTION_AUTHN_CONNECT,
                                                                           cspace.CSPACE_SHOULD_RELOAD_CONFIG)
        cls.initialize_authn(cls.config)
        cls.is_initialized = True


    def __init__(self):
        if ucb_deployment_site.shouldInitialize() is True:
            ucb_deployment_site.initialize()

    @classmethod
    def getConfig(cls):
        """
            Returns our site's config file.
        :return:
        """
        if ucb_deployment_site.shouldInitialize() is True:
            ucb_deployment_site.initialize()

        return ucb_deployment_site.config
