#
if [ -d solr4 ];
then
   echo "solr4 directory exists, please remove (e.g. rm -rf solr4/), then try again."
   exit
fi
tar xzf solr-4.10.0.tgz 
mv solr-4.10.0 solr4
cd solr4
mv example ucb

cd ucb/multicore/

rm -rf core0/
rm -rf core1/
rm -rf examplecdocs/

mkdir pahma
mkdir botgarden
mkdir ucjeps
mkdir cinefiles
mkdir bampfa

cp -r ../example-schemaless/solr/collection1 pahma/metadata
cp -r ../example-schemaless/solr/collection1 botgarden/metadata
cp -r ../example-schemaless/solr/collection1 botgarden/propagations
cp -r ../example-schemaless/solr/collection1 ucjeps/metadata
cp -r ../example-schemaless/solr/collection1 cinefiles/metadata
cp -r ../example-schemaless/solr/collection1 bampfa/metadata

#cp -r ../example-DIH/solr/solr pahma/metadata
#cp -r ../example-DIH/solr/solr botgarden/metadata
#cp -r ../example-DIH/solr/solr botgarden/propagations
#cp -r ../example-DIH/solr/solr ucjeps/metadata
#cp -r ../example-DIH/solr/solr cinefiles/metadata
#cp -r ../example-DIH/solr/solr bampfa/metadata
#
cp ~/solr.xml .
perl -i -pe 's/collection1/pahma-metadata/' pahma/metadata/core.properties
perl -i -pe 's/collection1/botgarden-metadata/' botgarden/metadata/core.properties
perl -i -pe 's/collection1/botgarden-propations/' botgarden/propagations/core.properties
perl -i -pe 's/collection1/ucjeps-metadata/' ucjeps/metadata/core.properties
perl -i -pe 's/collection1/cinefiles-metadata/' cinefiles/metadata/core.properties
perl -i -pe 's/collection1/bampfa-metadata/' bampfa/metadata/core.properties
#
# <schema name="example core zero" version="1.1">
# <schema name="example-schemaless" version="1.5">
perl -i -pe 's/example-schemaless/pahma-metadata/' pahma/metadata/conf/schema.xml
perl -i -pe 's/example-schemaless/botgarden-metadata/' botgarden/metadata/conf/schema.xml
perl -i -pe 's/example-schemaless/botgarden-propations/' botgarden/propagations/conf/schema.xml
perl -i -pe 's/example-schemaless/ucjeps-metadata/' ucjeps/metadata/conf/schema.xml
perl -i -pe 's/example-schemaless/cinefiles-metadata/' cinefiles/metadata/conf/schema.xml
perl -i -pe 's/example-schemaless/bampfa-metadata/' bampfa/metadata/conf/schema.xml

cp  ~/solrconfig.xml pahma/metadata/conf
cp  ~/solrconfig.xml botgarden/metadata/conf
cp  ~/solrconfig.xml botgarden/propagations/conf
cp  ~/solrconfig.xml ucjeps/metadata/conf
cp  ~/solrconfig.xml cinefiles/metadata/conf
cp  ~/solrconfig.xml bampfa/metadata

