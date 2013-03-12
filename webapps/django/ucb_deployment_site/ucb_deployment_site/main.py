import authn
from authn.authn import CSpaceAuthN
from common import cspace
from os import path

AUTHN_CONNECT = 'cspace_services_connect'


class ucb_deployment_site:
    __singleton = None

    def __init__(self):
        if ucb_deployment_site.__singleton is None:
            ucb_deployment_site.__singleton = self
            config = cspace.getConfig(path.dirname(__file__), "main.cfg")
            #
            # Read the required params from the config file
            #
            realm = cspace.getConfigOptionWithSection(config, AUTHN_CONNECT,
                                                      authn.authn.CSPACE_AUTHN_REALM_PROPERTY)
            uri = cspace.getConfigOptionWithSection(config, AUTHN_CONNECT,
                                                    authn.authn.CSPACE_AUTHN_URI_PROPERTY)
            hostname = cspace.getConfigOptionWithSection(config, AUTHN_CONNECT,
                                                         authn.authn.CSPACE_AUTHN_HOSTNAME_PROPERTY)
            protocol = cspace.getConfigOptionWithSection(config, AUTHN_CONNECT,
                                                         authn.authn.CSPACE_AUTHN_PROTOCOL_PROPERTY)
            port = cspace.getConfigOptionWithSection(config, AUTHN_CONNECT, authn.authn.CSPACE_AUTHN_PORT_PROPERTY)

            #  def initialize(realm=None, uri=None, hostname=None, protocol=HTTP_PROTOCOL, port=None):
            CSpaceAuthN.initialize(realm, uri, hostname, protocol, port)
        else:
            raise ucb_deployment_site.__singleton

    @classmethod
    def getInstance(cls):
        """
            This method should be made thread safe.

        :return:
        """
        result = ucb_deployment_site.__singleton
        if result is not None:
            return result
        else:
            return ucb_deployment_site()
