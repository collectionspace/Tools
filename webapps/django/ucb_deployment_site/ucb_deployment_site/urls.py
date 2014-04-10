from django.conf.urls import patterns, include, url

# Uncomment the next two lines to enable the admin:
from django.contrib import admin
from django.contrib.auth import views

admin.autodiscover()

#
# Initialize our web site -things like our AuthN backend need to be initialized.
#
from ucb_deployment_site.main import ucb_deployment_site
ucb_deployment_site.initialize()

urlpatterns = patterns('',
                       #  Examples:
                       #  url(r'^$', 'ucb_deployment_site.views.home', name='home'),
                       #  url(r'^ucb_deployment_site/', include('ucb_deployment_site.foo.urls')),

                       #  Uncomment the admin/doc line below to enable admin documentation:
                       #  url(r'^admin/doc/', include('django.contrib.admindocs.urls')),

                       #  Uncomment the next line to enable the admin:
                       url(r'^admin/', include(admin.site.urls)),
                       url(r'^polls/', include('polls.urls')),
                       url(r'^intakes/', include('intakes.urls')),
                       url(r'^accounts/login/$', views.login, name='login'),
                       )
