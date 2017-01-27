#!/bin/bash

DATA=invokePayload.xml
URL="http://localhost:8180/cspace-services/batch/c5e3e03c-1e1c-4d0b-966a"
CONTENT_TYPE="application/xml"
USER="admin@core.collectionspace.org:Administrator"
# Example: USER="admin@core.collectionspace.org:Administrator"

# Possible "mode" values:
# "single" - work against a single resource/record
# "list" - work against a list of resources/records
# "group" - work against a group resource/record
# "nocontext" - no specific resources/records will be supplied
#
# An example bath invocation payload.
#
#<?xml version="1.0" encoding="utf-8" standalone="yes"?>
#<ns2:invocationContext xmlns:ns2="http://collectionspace.org/services/common/invocable">
#	<mode>single</mode>
#	<docType>CollectionObject</docType>
#	<singleCSID>2100fa7f-a5b3-44ba-8fe8</singleCSID>
#	<groupCSID>658f912e-c038-4b72-a507</groupCSID>
#	<listCSIDs>
#		<csid>8ea674b2-9389-4f85-b652</csid>
#		<csid>4ca8819c-15e2-4862-9829</csid>
#	</listCSIDs>
#	<params> 
#		<param>
#			<key>cow</key>
#			<value>moo</value>
#		</param>
#		<param>
#			<key>bird</key>
#			<value>tweet</value>
#		</param>
#	</params>
#</ns2:invocationContext>

echo "Sending $DATA"
echo "to $URL"
echo "with content type $CONTENT_TYPE"
echo "as $USER"

curl -X POST $URL -i -u "$USER" -H "Content-Type: $CONTENT_TYPE" -T "$DATA" -o curl.out

#mv $DATA ${DATA}.done
cat curl.out