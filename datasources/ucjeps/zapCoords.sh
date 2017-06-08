cd ~/solrdatasources/ucjeps/
gunzip errors_in_latlong.csv.gz 
gunzip header4Solr.csv.gz 
awk -F'\t' -v OFS="\t" '{$25 = ""; print}' errors_in_latlong.csv > e2.csv 
cat header4Solr.csv e2.csv > e3
cut -f3,25 e3 | expand -20
curl -S -s 'http://localhost:8983/solr/ucjeps-public/update/csv?commit=true&header=true&trim=true&separator=%09&f.comments_ss.split=true&f.comments_ss.separator=%7C&f.collector_ss.split=true&f.collector_ss.separator=%7C&f.previousdeterminations_ss.split=true&f.previousdeterminations_ss.separator=%7C&f.otherlocalities_ss.split=true&f.otherlocalities_ss.separator=%7C&f.associatedtaxa_ss.split=true&f.associatedtaxa_ss.separator=%7C&f.typeassertions_ss.split=true&f.typeassertions_ss.separator=%7C&f.alllocalities_ss.split=true&f.alllocalities_ss.separator=%7C&f.othernumber_ss.split=true&f.othernumber_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,&f.card_ss.split=true&f.card_ss.separator=,&encapsulator=\' --data-binary @e3 -H 'Content-type:text/plain; charset=utf-8'
