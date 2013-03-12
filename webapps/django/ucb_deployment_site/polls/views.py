from django.http import HttpResponse
from common import cspace


def index(request):
    user = request.user
    realm             = 'org.collectionspace.services'
    uri               = 'cspace-services/accounts/0/accountperms'
    hostname          = 'demo.collectionspace.org'
    protocol          = 'http'
    port              = '8180'
    #return HttpResponse("Hello, world. You're at the poll index.")
    (url, data, statusCode) = cspace.make_get_request(realm, uri, hostname, protocol, port, \
                                                      username='admin@core.collectionspace.org', password='Administrator')
    return HttpResponse(data, mimetype='application/xml')


def detail(request, poll_id):
    return HttpResponse("You're looking at poll %s." % poll_id)


def results(request, poll_id):
    return HttpResponse("You're looking at the results of poll %s." % poll_id)


def vote(request, poll_id):
    return HttpResponse("You're voting on poll %s." % poll_id)