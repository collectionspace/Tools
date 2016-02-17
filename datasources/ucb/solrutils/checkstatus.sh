#!/usr/bin/env bash
for t in bampfa botgarden pahma ucjeps
do
    echo "============================================================================"
    for d in public internal propagations locations media
    do
       if [[ -e solrdatasources/${t}/solr_extract_${d}.log ]]
       then
           echo "${t}-${d}"
           grep '<int name="status">' solrdatasources/${t}/solr_extract_${d}.log | tail -1
           curl -s -S "http://localhost:8983/solr/${t}-${d}/select?q=*%3A*&wt=json&indent=true" | grep numFound
           tail -1 solrdatasources/${t}/solr_extract_${d}.log
           echo
       fi
    done
done
