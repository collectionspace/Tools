from authn.authn import CSpaceAuthN

#  def initialize(realm=None, uri=None, hostname=None, protocol=HTTP_PROTOCOL, port=None):
CSpaceAuthN.initialize("org.collectionspace.services",
                       "cspace-services/accounts/0/accountperms",
                       "demo.collectionspace.org",
                       "http",
                       "8180")
