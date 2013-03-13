__author__ = 'remillet'

from django.contrib.auth.decorators import login_required
from django.http import HttpResponse
from common import cspace
from ucb_deployment_site import main


@login_required()
def get_intakes(request):
    user = request.user
    config = main.ucb_deployment_site.getInstance().config
    connection = cspace.connection.create_connection(config, request.user)
    (url, data, statusCode) = connection.make_get_request('cspace-services/intakes')
    return HttpResponse(data, mimetype='application/xml')

@login_required()
def get_intake_detail(request, intake_csid):
    user = request.user
    config = main.ucb_deployment_site.getInstance().config
    connection = cspace.connection.create_connection(config, request.user)
    (url, data, statusCode) = connection.make_get_request('cspace-services/intakes/%s' % intake_csid)
    return HttpResponse(data, mimetype='application/xml')
