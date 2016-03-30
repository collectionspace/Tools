#!/usr/bin/env bash
# mostly untested!
set -e
if [ $# -lt 3 ];
then
  echo 1>&2 ""
  echo 1>&2 "First, cd to the directory in which you want solr4 installed. E.g cd ~ or cd /usr/local/share"
  echo 1>&2 ""
  echo 1>&2 "call with three arguments:"
  echo 1>&2 "$0 fullpathtotoolsdir fullpathtosolr4dir solrversion"
  echo 1>&2 ""
  echo 1>&2 "e.g."
  echo 1>&2 "$0  ~/Tools ~/solr4 4.10.4"
  echo 1>&2 ""
  echo 1>&2 ""
  echo 1>&2 "- path to Tool git repo"
  echo 1>&2 "- directory to create with all Solr goodies in it"
  echo 1>&2 "- solr4 version (e.g. 4.10.4)"
  echo 1>&2 "(toolsdir clone repo must exist; solr4dir must not)"
  echo 1>&2 ""
  exit 2
fi
TOOLS=$1
SOLR4=$2
SOLRVERSION=$3
if [ ! -d $TOOLS ];
then
   echo "Tools directory $TOOLS not found. Please clone from GitHub and provide it as the first argument."
   exit 1
fi
cd ${TOOLS}
git pull -v
if [ -d $SOLR4 ];
then
   echo "$SOLR4 directory exists, please remove (e.g. rm -rf $SOLR4/), then try again."
   exit 1
fi
if [ ! -e /tmp/solr-$SOLRVERSION.tgz ];
then
   echo "solr-$SOLRVERSION.tgz does not exist, attempting to download"
   # install solr
   curl -o /tmp/solr-$SOLRVERSION.tgz http://mirror.symnds.com/software/Apache/lucene/solr/$SOLRVERSION/solr-$SOLRVERSION.tgz
fi
tar xzf /tmp/solr-$SOLRVERSION.tgz
mv solr-$SOLRVERSION $SOLR4
cd $SOLR4
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

cp -r ../example-schemaless/solr/collection1 pahma/public
cp -r ../example-schemaless/solr/collection1 botgarden/public
cp -r ../example-schemaless/solr/collection1 ucjeps/public
cp -r ../example-schemaless/solr/collection1 cinefiles/public
cp -r ../example-schemaless/solr/collection1 bampfa/public

cp -r ../example-schemaless/solr/collection1 pahma/internal
cp -r ../example-schemaless/solr/collection1 botgarden/internal
cp -r ../example-schemaless/solr/collection1 ucjeps/internal
cp -r ../example-schemaless/solr/collection1 cinefiles/internal
cp -r ../example-schemaless/solr/collection1 bampfa/internal

# the special cases
cp -r ../example-schemaless/solr/collection1 pahma/locations
cp -r ../example-schemaless/solr/collection1 pahma/osteology
cp -r ../example-schemaless/solr/collection1 botgarden/propagations
cp -r ../example-schemaless/solr/collection1 ucjeps/media

cp $TOOLS/datasources/ucb/multicore/solr.xml .

perl -i -pe 's/collection1/pahma-public/' pahma/public/core.properties
perl -i -pe 's/collection1/botgarden-public/' botgarden/public/core.properties
perl -i -pe 's/collection1/ucjeps-public/' ucjeps/public/core.properties
perl -i -pe 's/collection1/cinefiles-public/' cinefiles/public/core.properties
perl -i -pe 's/collection1/bampfa-public/' bampfa/public/core.properties

perl -i -pe 's/collection1/pahma-internal/' pahma/internal/core.properties
perl -i -pe 's/collection1/botgarden-internal/' botgarden/internal/core.properties
perl -i -pe 's/collection1/ucjeps-internal/' ucjeps/internal/core.properties
perl -i -pe 's/collection1/cinefiles-internal/' cinefiles/internal/core.properties
perl -i -pe 's/collection1/bampfa-internal/' bampfa/internal/core.properties

perl -i -pe 's/collection1/pahma-locations/' pahma/locations/core.properties
perl -i -pe 's/collection1/pahma-osteology/' pahma/osteology/core.properties
perl -i -pe 's/collection1/botgarden-propagations/' botgarden/propagations/core.properties
perl -i -pe 's/collection1/ucjeps-media/' ucjeps/media/core.properties

#perl -i -pe 's/example-schemaless/pahma-public/' pahma/public/conf/schema.xml
#perl -i -pe 's/example-schemaless/botgarden-public/' botgarden/public/conf/schema.xml
#perl -i -pe 's/example-schemaless/botgarden-propagations/' botgarden/propagations/conf/schema.xml
#perl -i -pe 's/example-schemaless/ucjeps-public/' ucjeps/public/conf/schema.xml
#perl -i -pe 's/example-schemaless/cinefiles-public/' cinefiles/public/conf/schema.xml
#perl -i -pe 's/example-schemaless/bampfa-public/' bampfa/public/conf/schema.xml

cp $TOOLS/datasources/ucb/multicore/botgarden.public.solrconfig.xml botgarden/public/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/cinefiles.public.solrconfig.xml cinefiles/public/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/bampfa.public.solrconfig.xml bampfa/public/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/pahma.public.solrconfig.xml pahma/public/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/ucjeps.public.solrconfig.xml ucjeps/public/conf/solrconfig.xml

cp $TOOLS/datasources/ucb/multicore/botgarden.public.schema.xml botgarden/public/conf/schema.xml
cp $TOOLS/datasources/ucb/multicore/cinefiles.public.schema.xml cinefiles/public/conf/schema.xml
cp $TOOLS/datasources/ucb/multicore/bampfa.public.schema.xml bampfa/public/conf/schema.xml
cp $TOOLS/datasources/ucb/multicore/pahma.public.schema.xml pahma/public/conf/schema.xml
cp $TOOLS/datasources/ucb/multicore/ucjeps.public.schema.xml ucjeps/public/conf/schema.xml

cp $TOOLS/datasources/ucb/multicore/botgarden.internal.solrconfig.xml botgarden/internal/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/cinefiles.internal.solrconfig.xml cinefiles/internal/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/bampfa.internal.solrconfig.xml bampfa/internal/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/pahma.internal.solrconfig.xml pahma/internal/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/ucjeps.internal.solrconfig.xml ucjeps/internal/conf/solrconfig.xml

cp $TOOLS/datasources/ucb/multicore/botgarden.internal.schema.xml botgarden/internal/conf/schema.xml
cp $TOOLS/datasources/ucb/multicore/cinefiles.internal.schema.xml cinefiles/internal/conf/schema.xml
cp $TOOLS/datasources/ucb/multicore/bampfa.internal.schema.xml bampfa/internal/conf/schema.xml
cp $TOOLS/datasources/ucb/multicore/pahma.internal.schema.xml pahma/internal/conf/schema.xml
cp $TOOLS/datasources/ucb/multicore/ucjeps.internal.schema.xml ucjeps/internal/conf/schema.xml

cp $TOOLS/datasources/ucb/multicore/pahma.locations.schema.xml pahma/locations/conf/schema.xml
cp $TOOLS/datasources/ucb/multicore/pahma.osteology.schema.xml pahma/osteology/conf/schema.xml
cp $TOOLS/datasources/ucb/multicore/botgarden.propagations.schema.xml botgarden/propagations/conf/schema.xml
cp $TOOLS/datasources/ucb/multicore/ucjeps.media.schema.xml ucjeps/media/conf/schema.xml

cp $TOOLS/datasources/ucb/multicore/pahma.locations.solrconfig.xml pahma/locations/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/pahma.osteology.solrconfig.xml pahma/osteology/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/botgarden.propagations.solrconfig.xml botgarden/propagations/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/ucjeps.media.solrconfig.xml ucjeps/media/conf/solrconfig.xml

# these cores are special: they use the solr "managed-schema"
cp -r ../example-schemaless/solr/collection1 pahma/media
cp -r ../example-schemaless/solr/collection1 bampfa/media
cp -r ../example-schemaless/solr/collection1 cinefiles/media
#cp -r ../example-schemaless/solr/collection1 ucjeps/media
cp -r ../example-schemaless/solr/collection1 botgarden/media
perl -i -pe 's/collection1/pahma-media/' pahma/media/core.properties
perl -i -pe 's/collection1/bampfa-media/' bampfa/media/core.properties
perl -i -pe 's/collection1/cinefiles-media/' cinefiles/media/core.properties
#perl -i -pe 's/collection1/ucjeps-media/' ucjeps/media/core.properties
perl -i -pe 's/collection1/botgarden-media/' botgarden/media/core.properties
cp $TOOLS/datasources/ucb/multicore/pahma.media.solrconfig.xml pahma/media/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/bampfa.media.solrconfig.xml bampfa/media/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/cinefiles.media.solrconfig.xml cinefiles/media/conf/solrconfig.xml
#cp $TOOLS/datasources/ucb/multicore/ucjeps.media.solrconfig.xml ucjeps/media/conf/solrconfig.xml
cp $TOOLS/datasources/ucb/multicore/botgarden.media.solrconfig.xml botgarden/media/conf/solrconfig.xml
echo
echo "*** Multicore solr4 installed for UCB deployments! ****"
echo "You can now start solr4. A good way to do this for development purposes is to use"
echo "the script made for the purpose, in the $TOOLS/datasources/ucb/solrutils directory:"
echo "cp $TOOLS/datasources/ucb/solrutils/startSolr.sh ${SOLR4}/ucb"
echo "cd ${SOLR4}/ucb"
echo "./startSolr.sh"
echo
echo "You may also want to clean up a bit -- get rid of the clone of the Tools repo, unless you"
echo "think you'll need it again."
echo "rm -rf $TOOLS"
echo
echo "Let me try it for you..."
cp $TOOLS/datasources/ucb/solrutils/startSolr.sh ${SOLR4}/ucb
cd ${SOLR4}/ucb
./startSolr.sh
