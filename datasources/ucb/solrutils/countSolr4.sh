#!/usr/bin/env bash
for t in bampfa botgarden pahma ucjeps
do
    echo "$t ============================================================================"
    for d in public internal propagations locations media
    do
        echo "${t}-${d}"
        curl -s -S "http://localhost:8983/solr/${t}-${d}/select?q=*%3A*&wt=json&indent=true" | grep numFound | perl -pe 's/.*"numFound":(\d+),.*/\1/'
    done
done
