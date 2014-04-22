#
# sample script to deploy webapps from this GitHub directory on a local Linux VM
#
# NB: UNTESTED! SAMPLE ONLY! PROBABLY DOES NOT WORK AS IS!
#
# copy files to appropriate directories, keeping dir structure intact
#
git pull origin $1 -v
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
cp cswa*.py           /var/www/cgi-bin/
cp autosuggest.py     /var/www/cgi-bin/
cp -r ../extras/*.js  /var/www/js/
cp -r ../extras/css/*.css /var/www/css/
cp -r ../extras/*.png /var/www/images/
cp -r ../extras/*.jpg /var/www/images/
cp -r ../extras/*.svg /var/www/images/
cp -r ../extras/*.gif /var/www/icons/

cd /var/www/cgi-bin/
chmod a+x cswaMain.py
cd .. && chgrp -R developers cswa*.py

#Don't know about the other files, i.e.
#cp checkPlace.py      /var/www/cgi-bin/
#cp checkBlobs.py      /var/www/cgi-bin/
#cp getAuthority.py    /var/www/cgi-bin/
#cp getPlaces.py       /var/www/cgi-bin/
#cp getTaxname.py      /var/www/cgi-bin/
#cp badObjectNames.py  /var/www/cgi-bin/
#cp badObjectNamesDB.py /var/www/cgi-bin/
