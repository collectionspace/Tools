#!/bin/bash

# Script to run Maven dependencies reports in each Application
# layer module, then aggregate those reports in a top-level directory.
#
# This ad hoc script must be run from the top-level of the Application layer.
# There are currently no checks that this is being run in the correct
# location, except that the child directories for each module will not be found
# and hence the script should quickly finish processing with no meaningful results.

# Enable for verbose output - uncomment only while debugging!
# set -x verbose

# This list comes from the <modules> element in the top-level Application pom.xml file:
MODULES+=(
csp-api
csp-impl
cspi-schema
jxutils
csp-helper
cspi-webui
cspi-file
cspi-services
cspi-installation
tomcat-main
war-entry)

TARGET_DIR=target
DEPENDENCIES_DIR=dependencies
DEPENDENCIES_TARGET_DIR=$TARGET_DIR/$DEPENDENCIES_DIR
SITE_DIR=site
DEPENDENCIES_REPORT=dependencies.html
DEPENDENCIES_REPORT_PATH=$TARGET_DIR/$SITE_DIR/$DEPENDENCIES_REPORT

if [[ ! -d $TARGET_DIR ]];
  then
    mkdir $TARGET_DIR || \
      { echo "Creating directory $TARGET_DIR failed"; exit 1; }
fi

if [[ ! -d $DEPENDENCIES_TARGET_DIR ]];
  then
    mkdir $DEPENDENCIES_TARGET_DIR || \
      { echo "Creating directory $DEPENDENCIES_TARGET_DIR failed"; exit 1; }
fi

for module in ${MODULES[*]}
do
  echo "Processing dependencies report for module $module ..."
  cd $module
  mvn project-info-reports:dependencies -Ddependency.locations.enabled=false
  if [[ -e $DEPENDENCIES_REPORT_PATH && -r $DEPENDENCIES_REPORT_PATH ]];
    then
      cp $DEPENDENCIES_REPORT_PATH ../$DEPENDENCIES_TARGET_DIR/$module.html
  fi
  cd ..
done

echo "Finished writing dependencies reports to '$DEPENDENCIES_TARGET_DIR' directory." 
