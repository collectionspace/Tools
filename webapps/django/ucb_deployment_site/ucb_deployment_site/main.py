import authn
from authn.authn import CSpaceAuthN
from common import cspace
from os import path
from common import cspace


class ucb_deployment_site:
    __singleton = None
    config = None

    def __init__(self):
        """
            This method should be made thread safe.

        :raise:
        """
        if ucb_deployment_site.__singleton is None:
            ucb_deployment_site.__singleton = self
            self.config = cspace.getConfig(path.dirname(__file__), "main")
            #
            # Read the required params from the config file
            #
            realm = cspace.getConfigOptionWithSection(self.config,
                                                      cspace.AUTHN_CONNECT, cspace.CSPACE_REALM_PROPERTY)
            uri = cspace.getConfigOptionWithSection(self.config,
                                                    cspace.AUTHN_CONNECT, cspace.CSPACE_URI_PROPERTY)
            hostname = cspace.getConfigOptionWithSection(self.config,
                                                         cspace.AUTHN_CONNECT, cspace.CSPACE_HOSTNAME_PROPERTY)
            protocol = cspace.getConfigOptionWithSection(self.config,
                                                         cspace.AUTHN_CONNECT, cspace.CSPACE_PROTOCOL_PROPERTY)
            port = cspace.getConfigOptionWithSection(self.config,
                                                     cspace.AUTHN_CONNECT, cspace.CSPACE_PORT_PROPERTY)
            #
            #  def initialize(realm=None, uri=None, hostname=None, protocol=HTTP_PROTOCOL, port=None):
            #
            CSpaceAuthN.initialize(realm, uri, hostname, protocol, port)
        else:
            raise ucb_deployment_site.__singleton

    @classmethod
    def getInstance(cls):
        """

        :return:
        """
        result = ucb_deployment_site.__singleton
        if result is not None:
            return result
        else:
            return ucb_deployment_site()
