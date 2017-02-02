TENANT=$1
grep blobs ${TENANT}.django.log | cut -f9 | perl -pe 's/content.*/content/;s#derivatives/.*/content#derivatives/Thumbnail/content#' | sort | uniq -c | sort -rn | head -100 | perl -pe 's/^ *(\d+) /\1\t/' | grep -v image1blobcsid > ${TENANT}.blobs.txt
cut -f2 ${TENANT}.blobs.txt | perl -ne 'chomp; print "<a href=\"https://webapps.cspace.berkeley.edu/TTT/imageserver/$_\"><img src=\"https://webapps.cspace.berkeley.edu/TTT/imageserver/$_\"></a>\n"' | perl -pe "s/TTT/"$TENANT"/g" > ${TENANT}.blobs.html
mv ${TENANT}.blobs.html /var/www/static
