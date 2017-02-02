#! /usr/bin/env bash

####################################################
# Script for rolling up a daily tarball from nightly
####################################################

####################################################
# Start of variables to set
####################################################

# Enable for verbose output - uncomment while debugging,
# or when running via automation and thus logging messages
set -x verbose

# The $CATALINA_HOME environment variable must be set
# to identify the path to the Tomcat directory
ARCHIVE_DIR_NAME=`basename "$CATALINA_HOME"`

# Other variables to set; customize these as needed
TARBALL_NAME=$ARCHIVE_DIR_NAME-`date +%Y-%m-%d`.tar.gz
DESTINATION_DIR=/var/www/html/builds

# The following paths are all relative to the Tomcat directory
NUXEO_CONF_FILE=bin/nuxeo.conf
NUXEO_SERVER_DIR=nuxeo-server
NUXEO_SERVER_BUNDLES_DIR=$NUXEO_SERVER_DIR/bundles
NUXEO_SERVER_PLUGINS_DIR=$NUXEO_SERVER_DIR/plugins
NUXEO_REPO_CONF_FILE=$NUXEO_SERVER_DIR/repos/default/default.xml
NUXEO_DEFAULT_REPO_CONF_FILE=$NUXEO_SERVER_DIR/config/default-repo-config.xml
NUXEO_DATASOURCES_CONF_FILE=$NUXEO_SERVER_DIR/config/datasources-config.xml
WEBAPPS_DIR=webapps
CSPACE_DS_FILE=$WEBAPPS_DIR/cspace-ds.xml
CSPACE_SERVICES_DIR=$WEBAPPS_DIR/cspace-services
WEB_INF_DIR=$CSPACE_SERVICES_DIR/WEB-INF
WEB_INF_CONTEXT_FILE=$WEB_INF_DIR/classes/context.xml
WEB_INF_PERSISTENCE_FILE=$WEB_INF_DIR/classes/META-INF/persistence.xml
META_INF_CONTEXT_FILE=$CSPACE_SERVICES_DIR/META-INF/context.xml
CATALINA_CONF_FILE=conf/Catalina/localhost/cspace-services.xml
TOMCAT_USERS_FILE=conf/tomcat-users.xml
CATALINA_LIB_DIR=lib
APP_LAYER_CONFIG_DIR=$CATALINA_LIB_DIR
CATALINA_LOG_DIR=logs
CATALINA_LOG_FILE=$CATALINA_LOG_DIR/catalina.out

####################################################
# End of variables to set
####################################################

if [[ -z "$CATALINA_HOME" ]];
  then
    echo "Environment variable CATALINA_HOME was empty; it must be set"
    exit 1
fi

DEFAULT_TMP_DIR=/tmp
TMP_DIR=

if [[ ! -z "$TMPDIR" && -d $TMPDIR && -w $TMPDIR ]];
  then
    TMP_DIR=$TMPDIR
elif [[ -d "$DEFAULT_TMP_DIR" && -w "$DEFAULT_TMP_DIR" ]];
  then
    TMP_DIR=$DEFAULT_TMP_DIR
else
    echo "Could not find a suitable temporary directory"
    exit 1
fi

echo "Making temporary copy of the Tomcat directory excluding selected items ..."

rsync -avz \
--exclude 'bin/tomcat.pid' --exclude 'conf/Catalina' --exclude 'cspace' --exclude 'data' \
--exclude 'logs/*' --exclude 'nuxeo-server/*' --exclude 'temp/*' --exclude 'templates' \
--exclude 'webapps/collectionspace' --exclude 'webapps/cspace-ui' --exclude 'webapps/cspace-services' \
--exclude 'webapps/cspace-services.war' --exclude 'work' \
$CATALINA_HOME $TMP_DIR

cd $TMP_DIR/$ARCHIVE_DIR_NAME || \
  { echo "Changing directories to $TMP_DIR/$ARCHIVE_DIR_NAME failed"; exit 1; }

echo "Cleaning up temporary copy of the Tomcat directory ..."

# Some of the files below are now excluded from being copied via rsync, so the
# attempted 'sed' replacement(s) targeting those files will harmlessly fail.
echo "Removing passwords from various config files ..."

# Assumes we're running under either Mac OS X or Linux,
# with a presumed default version of 'sed' under either OS
SED_CMD=
# Assumes we're running under Mac OS X, with BSD 'sed'
if [[ "$OSTYPE" == "darwin*" ]];
  then
    SED_CMD="sed -i .bak"
# Defaults to assuming we're running under Linux, with GNU 'sed'
else
    SED_CMD="sed -i"
fi

$SED_CMD "s/nuxeo\.db\.user=.*/nuxeo.db.user=/" $NUXEO_CONF_FILE
$SED_CMD "s/nuxeo\.db\.password=.*/nuxeo.db.password=/" $NUXEO_CONF_FILE

# Note: using sed to edit XML is potentially brittle - ADR
$SED_CMD 's#\(<password>\)[^<].*\(</password>\)#\1\2#g' $CSPACE_DS_FILE
# FIXME: We might look into acting on an array of file paths when
# performing identical replacements, with these three below ...
$SED_CMD 's#\(<property name\=\"[Pp]assword\">\)[^<].*\(</property>\)#\1\2#g' $NUXEO_REPO_CONF_FILE
$SED_CMD 's#\(<property name\=\"[Pp]assword\">\)[^<].*\(</property>\)#\1\2#g' $NUXEO_DEFAULT_REPO_CONF_FILE
$SED_CMD 's#\(<property name\=\"[Pp]assword\">\)[^<].*\(</property>\)#\1\2#g' $NUXEO_DATASOURCES_CONF_FILE
# ... and with the identical replacements within this group as well:
$SED_CMD 's#\(password\=\"\)[^\"]*\(\".*\)#\1\2#g' $WEB_INF_CONTEXT_FILE
$SED_CMD 's#\(password\=\"\)[^\"]*\(\".*\)#\1\2#g' $WEB_INF_PERSISTENCE_FILE
$SED_CMD 's#\(<property name\=\"hibernate.connection.password" value\=\"\)[^"].*\(\"/>\)#\1\2#g' \
  $WEB_INF_PERSISTENCE_FILE
$SED_CMD 's#\(password\=\"\)[^\"]*\(\".*\)#\1\2#g' $META_INF_CONTEXT_FILE
$SED_CMD 's#\(password\=\"\)[^\"]*\(\".*\)#\1\2#g' $CATALINA_CONF_FILE
$SED_CMD 's#\(password\=\"\)[^\"]*\(\".*\)#\1\2#g' $TOMCAT_USERS_FILE
$SED_CMD 's#\(roles\=\"\)[^\"]*\(\".*\)#\1\2#g' $TOMCAT_USERS_FILE
# Note that the above may fail if a double-quote char is part of the password

echo "Removing temporary directories ..."
rm -Rv temp[0-9a-f]*

echo "Creating Nuxeo server bundles directory ..."
if [[ ! -d "$NUXEO_SERVER_BUNDLES_DIR" ]];
  then
    mkdir -p $NUXEO_SERVER_BUNDLES_DIR  || \
      { echo "Creating $NUXEO_SERVER_BUNDLES_DIR directory failed"; exit 1; }
fi

echo "Creating Nuxeo server plugins directory ..."
if [[ ! -d "$NUXEO_SERVER_PLUGINS_DIR" ]];
  then
    mkdir -p $NUXEO_SERVER_PLUGINS_DIR  || \
      { echo "Creating $NUXEO_SERVER_PLUGINS_DIR directory failed"; exit 1; }
fi

if [[ ! -e "$CATALINA_LOG_FILE" ]];
  then
    echo "Creating empty Tomcat log file, required by catalina.sh ..."
    touch $CATALINA_LOG_FILE  || \
      { echo "Creating $CATALINA_LOG_FILE failed"; exit 1; }
fi

echo "Removing nightly-specific and other host-specific config files ..."
find $APP_LAYER_CONFIG_DIR -name nightly-settings.xml -delete
find $APP_LAYER_CONFIG_DIR -name local-settings.xml -delete

# See http://stackoverflow.com/a/1120952
unset a i
while IFS= read -r -u3 -d $'\0' tenantpath; do
    tenantname=${tenantpath##*/} # Get last directory in relative path as tenant name
    echo "Removing obsolete local-settings.xml files for $tenantname tenant ..."
    rm $tenantpath/local-settings.xml
    echo "Resetting hostnames to 'localhost' in settings.xml ..."
    $SED_CMD 's#<baseurl>http://[^:]*:8180</baseurl>#<baseurl>http://localhost:8180</baseurl>#' \
        $tenantpath/settings.xml;
    $SED_CMD 's#<url>http://[^:]*:8180/cspace-services</url>#<url>http://localhost:8180/cspace-services</url>#' \
        $tenantpath/settings.xml;
    $SED_CMD 's#<ims-url>http://[^:]*:8180/#<ims-url>http://localhost:8180/#' \
        $tenantpath/settings.xml;
done 3< <(find $APP_LAYER_CONFIG_DIR/tenants -mindepth 1 -maxdepth 1 -type d -print0)
cd ..

echo "Removing services JAR files ..."
rm -Rv $CATALINA_LIB_DIR/cspace-services-authz.jar
rm -Rv $CATALINA_LIB_DIR/cspace-services-authn.jar

echo "Rolling up tarball ..."
cd $TMP_DIR
tar -zcf $TARBALL_NAME $ARCHIVE_DIR_NAME || \
  { echo "Creating tarball $ARCHIVE_DIR_NAME/$TARBALL_NAME failed"; exit 1; }

if [[ -d $TMP_DIR/$ARCHIVE_DIR_NAME && -w $TMP_DIR/$ARCHIVE_DIR_NAME ]];
  then
    echo "Removing temporary copy of the Tomcat directory ..."
    rm -R $TMP_DIR/$ARCHIVE_DIR_NAME || \
      { echo "Removing $TMP_DIR/$ARCHIVE_DIR_NAME failed"; } 
fi

if [[ -d $DESTINATION_DIR && -w $DESTINATION_DIR ]];
  then
    echo "Moving tarball to destination directory ..."
    mv $TARBALL_NAME $DESTINATION_DIR || \
      { echo "Moving tarball to $DESTINATION_DIR failed"; }
    echo "Tarball copied to $DESTINATION_DIR"
  else
    echo "Tarball copied to $TMP_DIR/$TARBALL_NAME"
fi

if [[ -e $DESTINATION_DIR/$TARBALL_NAME && -w $DESTINATION_DIR ]];
  then
    echo "Deleting all similar tarballs in destination directory older than 7 days ..."
    find $DESTINATION_DIR -name "$ARCHIVE_DIR_NAME-*tar.gz" -mtime +7 -delete
fi


