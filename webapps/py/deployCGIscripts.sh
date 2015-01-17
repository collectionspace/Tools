#
# sample script to deploy webapps from this GitHub directory on a local Linux VM
#
# copy files to appropriate directories
#
set -e
#
if [ -z "$1" ]
  then
    echo "Please specify GitHub branch as an argument"
    exit 1
fi

error=0
for f in cgi-bin js css images icons
do
    if [ ! -d /var/www/$f/ ]; then
        echo "/var/www/$f does not exist, please create it"
        error=1
    fi
done

if [ $error == 1 ]
  then
    echo "Please correct the directory issues above and try again."
    exit
fi
#
git pull origin $1 -v
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

#Don't know about the other files, i.e.
#cp checkPlace.py      /var/www/cgi-bin/
#cp checkBlobs.py      /var/www/cgi-bin/
#cp getAuthority.py    /var/www/cgi-bin/
#cp getPlaces.py       /var/www/cgi-bin/
#cp getTaxname.py      /var/www/cgi-bin/
#cp badObjectNames.py  /var/www/cgi-bin/
#cp badObjectNamesDB.py /var/www/cgi-bin/
