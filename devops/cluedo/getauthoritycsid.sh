curl -S --stderr curl2.tmp -X GET "$CSPACEURL/cspace-services/$1" --basic -u "$CSPACEUSER" -H "$CONTENT_TYPE" >> curl.tmp
perl -pe 's/<list/\n<list/g' curl.tmp | perl -ne 'while (s/<list\-item>.*?<csid>(.*?)<.*?<$ENV{EXTRACT}.*?>(.*?)<.*?<\/list\-item>//) { print "$1\n" }' >> csid.tmp
cat csid.tmp | head -1
rm csid.tmp curl.tmp curl2.tmp
