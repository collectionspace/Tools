if [ $# -ne 2 ]; then
    echo "Usage: $0 TENANT CORE"
    echo
    echo "where: TENANT = the name of a deployable tenant, e.g. pahma"
    echo "       CORE = name of solr core, e.g. public, internal, etc."
    echo
    echo "e.g. $0 pahma internal"
    echo
    exit
fi
head -1 4solr.$TENANT.$CORE.csv > header4Solr.csv
##############################################################################
# here are the schema changes needed: copy all the _s and _ss to _txt, and vv.
##############################################################################
perl -pe 's/\t/\n/g' header4Solr.csv| perl -ne 'chomp; next unless /_txt/; s/_txt$//; print "    <copyField source=\"" .$_."_txt\" dest=\"".$_."_s\"/>\n"' > ${TENANT}.${CORE}.schemaFragment.xml
perl -pe 's/\t/\n/g' header4Solr.csv| perl -ne 'chomp; next unless /_s$/; s/_s$//; print "    <copyField source=\"" .$_."_s\" dest=\"".$_."_txt\"/>\n"' >> ${TENANT}.${CORE}.schemaFragment.xml
perl -pe 's/\t/\n/g' header4Solr.csv| perl -ne 'chomp; next unless /_ss$/; s/_ss$//; print "    <copyField source=\"" .$_."_ss\" dest=\"".$_."_txt\"/>\n"' >> ${TENANT}.${CORE}.schemaFragment.xml
##############################################################################
# here are the solr csv update parameters needed for multivalued fields
##############################################################################
perl -pe 's/\t/\n/g' header4Solr.csv| perl -ne 'chomp; next unless /_ss/; next if /blob/; print "f.$_.split=true&f.$_.separator=%7C&"' > ${TENANT}.${CORE}.uploadparms.txt
