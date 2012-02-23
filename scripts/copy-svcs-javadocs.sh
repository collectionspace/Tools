#!/bin/bash

####################################################
# Script for copying the Services layer Javadoc 
# documentation, from a Bamboo build directory 
# to a web-accessible directory: /apidocs/services
#
# Must be run as the Bamboo user
####################################################

####################################################
# Start of variables to set
####################################################

# Enable for verbose output - uncomment only while debugging!
set -x verbose

REQUIRED_USER=bamboo

SOURCE_DIR_NAME=apidocs
# SOURCE_JAR_FILENAME=org.collectionspace.services-javadoc.jar

BAMBOO_BUILD_PLAN=COLLECTIONSPACE1-DEF1-JOB1
BAMBOO_BUILD_DIR=$BAMBOO_HOME/xml-data/build-dir/$BAMBOO_BUILD_PLAN
SOURCE_DIR=$BAMBOO_BUILD_DIR/services/target/site/$SOURCE_DIR_NAME
# SOURCE_JAR_FILE=$BAMBOO_BUILD_DIR/services/target/$SOURCE_JAR_FILENAME

WEB_ROOT_DOCS_DIR=/var/www/html
DEST_DIR=$WEB_ROOT_DOCS_DIR/$SOURCE_DIR_NAME/services

####################################################
# End of variables to set
####################################################

if [ "x$REQUIRED_USER" == "x" ]
  then
    echo "Variable REQUIRED_USER was empty; it must be set"
    exit 1
fi

EFFECTIVE_USER=`echo "$(whoami)"`
if [ $EFFECTIVE_USER != $REQUIRED_USER ]
  then
    echo "Script must be run as user $REQUIRED_USER"
    exit 1
fi

if [ "x$BAMBOO_HOME" == "x" ]
  then
    echo "Environment variable BAMBOO_HOME was empty; it must be set"
    exit 1
fi

# if [ "x$JAVA_HOME" == "x" ]
#   then
#     echo "Environment variable JAVA_HOME was empty; it must be set"
#     exit 1
# fi

if [ ! -d $SOURCE_DIR ] 
  then
    echo "Source directory $SOURCE_DIR does not exist"
    exit 1
fi

# if [ ! -f $SOURCE_JAR_FILE ] 
#   then
#     echo "Source JAR file $SOURCE_JAR_FILE does not exist"
#     exit 1
# fi

if [ ! -d $WEB_ROOT_DOCS_DIR ] 
  then
    echo "Web root documents directory $WEB_ROOT_DOCS_DIR does not exist"
    exit 1
fi

if [ -d DEST_DIR ] 
  then
    if [ ! -O $DEST_DIR ] 
      then
        echo "Destination directory $DEST_DIR is not owned by the current effective user"
        exit 1
      else
        echo "Removing old destination directory ..."
        rm -R $DEST_DIR || \
          { echo "Removing $DEST_DIR failed"; exit 1; } 
    fi
fi

echo "Copying Javadoc directory to destination ..."
cp -Rf $SOURCE_DIR $DEST_DIR || \
  { echo "Copying $SOURCE_DIR to $DEST_DIR failed"; exit 1; } 

# echo "Copying JAR file to destination ..."
# cp -Rf $SOURCE_JAR_FILE $WEB_ROOT_DOCS_DIR || \
#  { echo "Copying $SOURCE_JAR_FILE to $WEB_ROOT_DOCS_DIR failed"; exit 1; } 
# cd $WEB_ROOT_DOCS_DIR
# echo "Extracting JAR file ..."
# $JAVA_HOME/bin/jar -xf $SOURCE_JAR_FILENAME || \
#  { echo "Extracting JAR file $SOURCE_JAR_FILENAME failed"; exit 1; } 

