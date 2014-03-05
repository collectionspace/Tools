#
# sample script to deploy webapps from this GitHub directory on a local Linux VM
#
# NB: UNTESTED! SAMPLE ONLY! PROBABLY DOES NOT WORK AS IS!
#
# copy files to approrpriate directories, keeping dir structure intact
#
git pull origin $1 -v
cp cswa*.py           /var/www/cgi-bin/
cp autosuggest.py     /var/www/cgi-bin/
cp -r ../extras/*.js  /var/www/js/
cp -r ../extras/css/*.css /var/www/css/
cp -r ../extras/*.png /var/www/images/
cp -r ../extras/*.jpg /var/www/images/
cp -r ../extras/*.gif /var/www/icons/
#
# what about .cfg files...?
