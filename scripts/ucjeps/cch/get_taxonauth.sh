#!/bin/sh
# get the following data for records in the Default Scientific Name Taxonomy Authority
#	csid
#	display name
#	refname
#	no author name (if available)
#	major group
# takes taxonomyauthority_common.shortidentifier as parameter
#	common = Common Taxononomy Authority
#	unverified = Unverified Taxononomy Authority
#	taxon = =Default Scientific Taxonomy Authority
# eg: ./get_taxonauth.sh taxon

if [ $# -lt 1 ]; then
	echo ""
	echo "ERROR: Usage: get_taxonauth.sh auth_shortid"
	echo "       e.g:   get_taxonauth.sh taxon"
	echo ""
	exit
elif [[ "$1" != "taxon" && "$1" != "unverified" && "$1" != "common" ]]; then
	echo ""
	echo "ERROR: valid values for taxonomy authority short identifiers are:"
	echo "	common = Common Taxononomy Authority"
	echo "	unverified = Unverified Taxononomy Authority"
	echo "	taxon = Default Scientific Taxonomy Authority"
	echo ""
	echo "Usage: get_taxonauth.sh auth_shortid"
	echo "e.g:   get_taxonauth.sh taxon"
	echo ""
	exit
fi

YYMMDD=`date +%y%m%d`
HOMEDIR=/home/app_webapps/extracts
AUTH_DIR=$HOMEDIR/taxonauth
AUTH_FILE=$AUTH_DIR/$1_auth_$YYMMDD.txt
AUTH_LOG=$AUTH_DIR/taxonauth_export.log

if [ ! -d "$AUTH_DIR" ]; then
	mkdir $AUTH_DIR
	echo "Made directory $AUTH_DIR"
fi

cd $AUTH_DIR

date >> $AUTH_LOG

psql -h dba-postgres-prod-32.ist.berkeley.edu -p 5310 -d ucjeps_domain_ucjeps -U reporter_ucjeps << HP_END >> $AUTH_LOG

create temp table tmp_taxon_auth as
select
	0 as line,
	'csid' as csid,
	'displayname' as displayname,
	'refname' as refname,
	'noauthorname' as noauthorname,
	'majorgroup' as majorgroup
from taxon_common tc
union
select
	1 as line,
	htc.name as csid,
	getdispl(tc.refname) as displayname,
	tc.refname as refname,
	ttg.termname as noauthorname,
	tu.taxonmajorgroup as majorgroup
from taxon_common tc
left outer join hierarchy htc on (tc.id = htc.id)
left outer join hierarchy httg on (
	tc.id = httg.parentid
	and httg.primarytype = 'taxonTermGroup'
	and httg.pos = 0)
left outer join taxontermgroup ttg on (httg.id = ttg.id)
left outer join taxon_ucjeps tu on (tc.id = tu.id)
left outer join hierarchy htac on (tc.inauthority = htac.name)
left outer join taxonomyauthority_common tac on (htac.id = tac.id)
where tac.shortidentifier = '$1'
;

\copy (select * from tmp_taxon_auth order by line, displayname) to '$AUTH_FILE.tmp' with null as ''

HP_END

cut -f2- $AUTH_FILE.tmp > $AUTH_FILE

ls -lt *.txt | head -1 >> $AUTH_LOG

wc -l $AUTH_FILE >> $AUTH_LOG

rm -f $AUTH_FILE.tmp

gzip $AUTH_FILE

echo '' >> $AUTH_LOG

