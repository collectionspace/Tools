#!/bin/bash
# Basic for loop

if [ -z $1 ]
then
	echo "A domain of the form 'abc.xyz.pdq' is required."
	exit -1
else
	domain=$1
fi

names='anthro bonsai botgarden core fcart herbarium lhmc materials publicart testsci'
for name in $names
do
	wget http://$domain:8180/collectionspace/ui/$name/html/index.html
done
echo All done