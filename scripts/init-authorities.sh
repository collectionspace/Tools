#!/bin/bash

####################################################
# Script for initializing authorities and
# vocabulary items in selected tenants.
#
# This is a general outline of what this script
# likely needs to do, but is not yet working;
# the initial authentication attempt appears to
# fail, with a redirect to a failure login page.
# - ADR 2012-05-30
####################################################

####################################################
# Start of variables to set
####################################################

# Enable for verbose output - uncomment only while debugging!
# set -x verbose

# Enter a space-separated list of tenant identifiers
TENANTS+=(core lifesci)
DEFAULT_ADMIN_ACCTS+=()

DEFAULT_ADMIN_PASSWORD=Administrator

####################################################
# End of variables to set
####################################################

let ACCT_COUNTER=0
for item in ${TENANTS[*]}
do
  DEFAULT_ADMIN_ACCTS[ACCT_COUNTER]="admin%40$item.collectionspace.org"
  let ACCT_COUNTER++
done

CURL_EXECUTABLE=`which curl`
if [ "xCURL_EXECUTABLE" == "x" ]
  then
    echo "Could not find 'curl' application"
    exit 1
fi

let TENANT_COUNTER=0
for tenant in ${TENANTS[*]}
do

  tempfilename=`basename $0`
  TMPFILE=`mktemp -t ${tempfilename}` || exit 1
  echo "tempfile=$TMPFILE"

  # Log into a tenant as an admin user, saving the response
  # headers - which include a session cookie - to a temporary file
  
  #######################################################
  # FIXME: This login request is currently failing;
  # the 303 response is returning in the Location: header
  # /collectionspace/ui/core/html/index.html?result=fail
  #######################################################
  
  $CURL_EXECUTABLE \
  -X POST \
  -i \
  -s \
  http://localhost:8280/collectionspace/tenant/$tenant/login \
  -d "login=${DEFAULT_ADMIN_ACCTS[TENANT_COUNTER]}&password=$DEFAULT_ADMIN_PASSWORD" > TMPFILE
    
  # Read the response headers from that file
  results=( $( < TMPFILE ) )
  
  # Extract the session cookie from the response headers
  COOKIE_REGEX="CSPACESESSID=.*;"
  cookie=""
  for results_item in ${results[*]}
  do
    if [[ $results_item =~ $COOKIE_REGEX ]]; then
      cookie="$results_item"
      cookie="${cookie%?}" # Strip the trailing ';' from the cookie
      echo "cookie=$cookie"
    fi
  done
  
  rm TMPFILE
  
  # If we got a session cookie, then initialize authorities using that cookie
  if [ "xcookie" != "x" ]
    then
        $CURL_EXECUTABLE \
        -X GET \
        -i \
        --connect-timeout 60 \
        -H "Cookie: $cookie" \
        http://localhost:8280/collectionspace/tenant/$tenant/authorities/initialise \
        -u "${DEFAULT_ADMIN_ACCTS[TENANT_COUNTER]}:$DEFAULT_ADMIN_PASSWORD"
  fi
  
  let TENANT_COUNTER++
  
done

