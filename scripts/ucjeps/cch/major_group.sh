#!/bin/sh

YYMMDD=`date +%y%m%d`
HOMEDIR=/home/app_webapps/extracts
MG_DIR=$HOMEDIR/major_group
MG_LOG=$HOMEDIR/major_group/major_group.log
MG_FILE=$HOMEDIR/major_group/major_group_$YYMMDD.txt

echo 'query START time: ' `date` >> $MG_LOG

#psql -d ucjeps_domain_ucjeps -U reporter_ucjeps << HP_END >> $MG_LOG
psql -h dba-postgres-prod-32.ist.berkeley.edu -p 5310 -d ucjeps_domain_ucjeps -U reporter_ucjeps << HP_END >> $MG_LOG

create temp table tmp_major_group_accn as
select
	co.objectnumber as accession_num,
	tu.taxonmajorgroup as major_group,
	createdby as created_by,
	date(createdat) as created_date,
	updatedby as updated_by,
	date(updatedat) as updatedi_date
from collectionobjects_common co
left outer join hierarchy h
	on (co.id = h.parentid and h.pos = 0
		and h.name = 'collectionobjects_naturalhistory:taxonomicIdentGroupList')
left outer join taxonomicIdentGroup tig on (tig.id = h.id)
left outer join taxon_common tc on (tc.refname = tig.taxon)
left outer join taxon_ucjeps tu on (tu.id = tc.id)
join collectionspace_core csc on (csc.id = co.id)
join misc m on (m.id = co.id and m.lifecyclestate != 'deleted')
where co.objectnumber not like '%test%'
order by objectnumber;

\copy (select * from tmp_major_group_accn order by accession_num) to '$MG_FILE' with null as ''

HP_END

echo 'query END time: ' `date` >> $MG_LOG

ls -l $MG_FILE >> $MG_LOG

wc -l $MG_FILE >> $MG_LOG

gzip -c $MG_FILE > $MG_FILE.gz

rm -f $MG_FILE

echo '' >> $MG_LOG

