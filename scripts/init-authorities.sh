#!/bin/bash

####################################################
# Script for initializing authorities and
# vocabulary items in selected tenants.
####################################################

####################################################
# Start of variables to set
####################################################

# Enable for verbose output - uncomment only while debugging!
# set -x verbose

# Set a space-separated list of tenant identifiers below:
TENANTS+=(core lifesci)

# This script assumes that each tenant's default administrator
# username follows a consistent pattern:
#   admin@{tenantidentifier}.collectionspace.org
# and that the passwords for each such account are identical,
# as per the variable set below:
DEFAULT_ADMIN_PASSWORD=Administrator

# Set the CollectionSpace hostname or IP address, and port below:
HOST=localhost
PORT=8180

####################################################
# End of variables to set
####################################################

DEFAULT_ADMIN_ACCTS+=()
let ACCT_COUNTER=0
for tenant in ${TENANTS[*]}
do
  DEFAULT_ADMIN_ACCTS[ACCT_COUNTER]="admin@$tenant.collectionspace.org"
  let ACCT_COUNTER++
done

CURL_EXECUTABLE=`which curl`
if [ "xCURL_EXECUTABLE" == "x" ]
  then
    echo "Could not find 'curl' application"
    exit 1
fi

LOGIN_FAILURE_REGEX="result=fail"
COOKIE_REGEX="CSPACESESSID=.*;"

let TENANT_COUNTER=0
for tenant in ${TENANTS[*]}
do

  tempfilename=`basename $0`
  TMPFILE=`mktemp -t ${tempfilename}` || exit 1

  # Log into a tenant as an admin user, saving the response
  # headers - which include a session cookie - to a temporary file
  
  echo "Logging into the '$tenant' tenant ..."
  
  $CURL_EXECUTABLE \
  --include \
  --silent \
  --data-urlencode "userid=${DEFAULT_ADMIN_ACCTS[TENANT_COUNTER]}" \
  --data-urlencode "password=$DEFAULT_ADMIN_PASSWORD" \
  http://$HOST:$PORT/collectionspace/tenant/$tenant/login \
  > $TMPFILE
  
  # AIUI, the following should not be needed in combination with
  # --data-urlencode or --data, which should do an implicit POST
  # with the specified Content-Type header:
  # --request POST \
  # --header "Content-Type: application/x-www-form-urlencoded" \

  # Read the response headers from that file
  results=( $( < $TMPFILE ) )
  
  # Check for a redirect to a failure page
  failure_flag=0
  for results_item in ${results[*]}
  do
    if [[ $results_item =~ $LOGIN_FAILURE_REGEX ]]; then
      failure_flag=1
      break
    fi
  done
  
  if [ $failure_flag == 1 ]; then
    echo "ERROR: Failed to log into the '$tenant' tenant."
    echo "(Suggestion: check username, password, tenant identifier, host and port.)"
    continue
  fi

  # Extract the session cookie from the response headers
  cookie=""
  for results_item in ${results[*]}
  do
    if [[ $results_item =~ $COOKIE_REGEX ]]; then
      cookie="$results_item"
      cookie="${cookie%?}" # Strip the trailing ';' from the cookie
      break
    fi
  done
  
  rm $TMPFILE
    
  # If we got a session cookie, then initialize authorities using that cookie
  if [ "xcookie" != "x" ]
    then
        echo "Initializing authorities in the '$tenant' tenant ..."

        $CURL_EXECUTABLE \
        --request GET \
        --include \
        --connect-timeout 60 \
        --header "Cookie: $cookie" \
        http://$HOST:$PORT/collectionspace/tenant/$tenant/authorities/initialise
        
        # If the user name and password credentials must be included in this call:
        # --user "${DEFAULT_ADMIN_ACCTS[TENANT_COUNTER]}:$DEFAULT_ADMIN_PASSWORD" \
    else
        echo "Could not obtain an authorization Cookie for the '$tenant' tenant ..."
        echo "Skipping the step of initializing authorities for that tenant ..."
  fi
  
  # FIXME: Add call to .../vocab/initialize here, after we've identified its purpose
  
  let TENANT_COUNTER++
  
done

