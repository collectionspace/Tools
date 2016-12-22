for t in bampfa botgarden pahma ucjeps
do
    for d in public internal propagations locations media osteology
    do
       if [[ -e solrdatasources/${t}/solr_extract_${d}.log ]]
       then
           CORE="${t}-${d}"
           DATE=`tail -1 solrdatasources/${t}/solr_extract_${d}.log | perl -ne 'if (/(Sun|Mon|Tue|Wed|Thu|Fri|Sat)/){print}else{print "PROBLEM: log file does not show a date as last line"}'`
           NUMFOUND=`curl -s -S "http://localhost:8983/solr/${t}-${d}/select?q=*%3A*&rows=0&wt=json&indent=true" | grep numFound | perl -pe 's/.*"numFound":(\d+),.*/\1 rows/;'`
           STATUS=`grep responseHeader solrdatasources/${t}/solr_extract_${d}.log | tail -1 | perl -ne 'unless (/<int name=.status.>0<.int>/) {print "\nNon-zero status from Solr:\n$_"}'`
           if [ "-v" == "$1" ] || [ `echo "$DATE" | grep -q "PROBLEM"` ] || [ "$STATUS" != "" ]            
           then
               echo "$CORE,$DATE,$NUMFOUND $STATUS"
           fi
       fi
    done
done
