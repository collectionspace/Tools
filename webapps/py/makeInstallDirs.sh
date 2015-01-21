#
# for RedHat only (i.e. these are the Apache CGI dirs that need to exist...
#
if [ ! -d /var/www/cgi-bin/ ]; then
    mkdir -p /var/www/cgi-bin/
fi
if [ ! -d /var/www/js/ ]; then
    mkdir -p /var/www/js/
fi
if [ ! -d /var/www/css/ ]; then
    mkdir -p /var/www/css/
fi
if [ ! -d /var/www/images/ ]; then
    mkdir -p /var/www/images/
fi
if [ ! -d /var/www/icons/ ]; then
    mkdir -p /var/www/icons/
fi
