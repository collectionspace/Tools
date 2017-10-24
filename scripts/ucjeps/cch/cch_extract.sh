#!/bin/sh
# includes collection object csid to generate link
# does not include major group filter to exclude algae, bryophytes, and lichen
# 08/01/2013 include other numbers in annovoucher query.

YYMMDD=`date +%y%m%d`
HOMEDIR=/home/app_webapps/extracts
CCH_DIR=$HOMEDIR/cch/current
CCH_LOG=$HOMEDIR/cch/cch_extract.log

# clean out any data from previous runs
rm $CCH_DIR/*

date >> $CCH_LOG

psql -h dba-postgres-prod-32.ist.berkeley.edu -p 5310 -d ucjeps_domain_ucjeps -U reporter_ucjeps << HP_END >> $CCH_LOG

create temp table tmp_cch_accessions as
select
	co.objectnumber as AccessionNumber,
	hcoc.name as CSID,
	case
		when (tig.taxon is not null and tig.taxon <> '')
		then regexp_replace(tig.taxon, '^.*\)''(.*)''$', '\1')
	end as Determination,
	case
		when (fc.item is not null and fc.item <> '')
		then regexp_replace(fc.item, '^.*\)''(.*)''$', '\1')
	end as Collector,
	co.fieldcollectionnumber as CollectorNumber,
	sdg.datedisplaydate as CollectionDate,
	case
		when
			sdg.dateearliestsingleyear != 0
			and sdg.dateearliestsinglemonth != 0
			and sdg.dateearliestsingleday != 0
		then to_date(
			sdg.dateearliestsingleyear::varchar(4) || '-' ||
			sdg.dateearliestsinglemonth::varchar(2) || '-' ||
			sdg.dateearliestsingleday::varchar(2),
			'yyyy-mm-dd')
		else null
	end as EarlyCollectionDate,
	case
		when
			sdg.datelatestyear != 0
			and sdg.datelatestmonth != 0
			and sdg.datelatestday != 0
		then to_date(
			sdg.datelatestyear::varchar(4) || '-' ||
			sdg.datelatestmonth::varchar(2) || '-' ||
			sdg.datelatestday::varchar(2),
			'yyyy-mm-dd')
		else null
	end as LateCollectionDate,
	lg.fieldlocverbatim as Locality,
	lg.fieldloccounty as County,
	lg.velevation as Elevation,
	lg.minelevation as MinElevation,
	lg.maxelevation as MaxElevation,
	lg.elevationunit as ElevationUnit,
	co.fieldcollectionnote as Habitat,
	lg.decimallatitude as DecLatitude,
	lg.decimallongitude as DecLongitude,
	case
		when lg.vcoordinates like '%; Meridian%'
		then regexp_replace(lg.vcoordinates, '^(TRS: )(.*)(; Meridian.*)$', '\2')
		when lg.vcoordinates like 'TRS: %' 
		then regexp_replace(lg.vcoordinates, '^(TRS: )(.*)$', '\2')
		else lg.vcoordinates
	end as TRSCoordinates,
	lg.geodeticdatum as Datum,
	lg.localitysource as CoordinateSource,
	lg.coorduncertainty as CoordinateUncertainty,
	lg.coorduncertaintyunit as CoordinateUncertaintyUnit
from collectionobjects_common co
inner join misc on co.id = misc.id
left outer join hierarchy hcoc on (co.id = hcoc.id)
left outer join collectionobjects_common_fieldCollectors fc
	on (co.id = fc.id
	and fc.pos = 0)
left outer join hierarchy hfcdg
	on (co.id = hfcdg.parentid
	and hfcdg.name = 'collectionobjects_common:fieldCollectionDateGroup')
left outer join structureddategroup sdg on (sdg.id = hfcdg.id)
left outer join hierarchy htig
	on (co.id = htig.parentid
	and htig.pos = 0
	and htig.name = 'collectionobjects_naturalhistory:taxonomicIdentGroupList')
left outer join taxonomicIdentGroup tig on (tig.id = htig.id)
left outer join hierarchy hlg
	on (co.id = hlg.parentid
	and hlg.pos = 0
	and hlg.name = 'collectionobjects_naturalhistory:localityGroupList')
left outer join localitygroup lg on (lg.id = hlg.id)
where misc.lifecyclestate <> 'deleted'
and (lg.fieldlocstate = 'CA' or lg.fieldlocstate = 'Baja California')
and substring(co.objectnumber from '^[A-Z]*') not in ('DHN', 'GOD', 'UCSB', 'UCSC');

\copy (select * from tmp_cch_accessions order by AccessionNumber) to '$CCH_DIR/cch_accessions.txt' with null as ''

create temp table tmp_cch_determinations as
select
	co.objectnumber as AccessionNumber,
	hcoc.name as CSID,
	htig.pos as Position,
	regexp_replace(tig.taxon, '^.*\)''(.*)''$', '\1') as Determination,
	tig.qualifier as Qualifier,
	regexp_replace(tig.identby, '^.*\)''(.*)''$', '\1') as IdBy,
	sdg.datedisplaydate as IdDate,
	tig.identkind as IdKind,
	tig.notes as Notes
from collectionobjects_common co
inner join misc on co.id = misc.id
left outer join hierarchy hcoc on (co.id = hcoc.id)
left outer join hierarchy htig
	on (co.id = htig.parentid
	and htig.name = 'collectionobjects_naturalhistory:taxonomicIdentGroupList')
left outer join taxonomicIdentGroup tig on (tig.id = htig.id)
left outer join hierarchy hidg
	on (tig.id = hidg.parentid
	and hidg.name = 'identDateGroup')
left outer join structureddategroup sdg on (sdg.id = hidg.id)
left outer join hierarchy hlg
	on (co.id = hlg.parentid
	and hlg.pos = 0
	and hlg.name = 'collectionobjects_naturalhistory:localityGroupList')
left outer join localitygroup lg on (lg.id = hlg.id)
where misc.lifecyclestate <> 'deleted'
and (lg.fieldlocstate = 'CA' or lg.fieldlocstate = 'Baja California')
and substring(co.objectnumber from '^[A-Z]*') not in ('DHN', 'GOD', 'UCSB', 'UCSC')
and regexp_replace(tig.taxon, '^.*\)''(.*)''$', '\1') != 'no name';

\copy (select * from tmp_cch_determinations order by AccessionNumber, Position) to '$CCH_DIR/cch_determinations.txt' with null as ''

create temp table tmp_cch_typespecimens as
select distinct
	co.objectnumber as AccessionNumber,
	hcoc.name as CSID,
	tsg.typespecimenkind as TypeKind,
	regexp_replace(tsg.typespecimenbasionym, '^.*\)''(.*)''$', '\1') as Basionym,
	regexp_replace(tsg.typespecimenassertionby, '^.*\)''(.*)''$', '\1') as AssertionBy
from collectionobjects_common co
inner join misc on co.id = misc.id
inner join hierarchy hcoc on (co.id = hcoc.id)
inner join hierarchy htsg
	on (co.id = htsg.parentid
	and htsg.name = 'collectionobjects_naturalhistory:typeSpecimenGroupList')
inner join typespecimengroup tsg on (tsg.id = htsg.id)
inner join hierarchy hlg
	on (co.id = hlg.parentid
	and hlg.pos = 0
	and hlg.name = 'collectionobjects_naturalhistory:localityGroupList')
inner join localitygroup lg on (lg.id = hlg.id)
where misc.lifecyclestate <> 'deleted'
and (lg.fieldlocstate = 'CA' or lg.fieldlocstate = 'Baja California')
and substring(co.objectnumber from '^[A-Z]*') not in ('DHN', 'GOD', 'UCSB', 'UCSC')
and tsg.typespecimenkind is not null;

\copy (select * from tmp_cch_typespecimens order by AccessionNumber, TypeKind) to '$CCH_DIR/cch_typespecimens.txt' with null as ''

create temp table tmp_cch_annovouchers as
select distinct
	co.objectnumber as AccessionNumber,
	hcoc.name as CSID,
	ag.annotationtype as VoucherKind,
	ag.annotationnote as Voucher
from collectionobjects_common co
inner join misc on co.id = misc.id
inner join hierarchy hcoc on (co.id = hcoc.id)
inner join hierarchy hag
	on (co.id = hag.parentid
	and hag.name = 'collectionobjects_naturalhistory:annotationGroupList')
inner join annotationgroup ag on (ag.id = hag.id)
inner join hierarchy hlg
	on (co.id = hlg.parentid
	and hlg.name = 'collectionobjects_naturalhistory:localityGroupList'
	and hlg.pos = 0)
inner join localitygroup lg on (lg.id = hlg.id)
where misc.lifecyclestate <> 'deleted'
and (lg.fieldlocstate = 'CA' or lg.fieldlocstate = 'Baja California')
and (ag.annotationtype is not null or ag.annotationnote is not null)
and substring(co.objectnumber from '^[A-Z]*') not in ('DHN', 'GOD', 'UCSB', 'UCSC')
union
select distinct
	co.objectnumber as AccessionNumber,
	null as CSID,
	'other number' as VoucherKind,
	concat_othernumber(co.id) as Voucher
from collectionobjects_common co
inner join misc on co.id = misc.id
inner join hierarchy ho
	on (co.id = ho.parentid
	and ho.primarytype = 'otherNumber')
inner join otherNumber o on (o.id = ho.id)
inner join hierarchy hlg
	on (co.id = hlg.parentid
	and hlg.name = 'collectionobjects_naturalhistory:localityGroupList'
	and hlg.pos = 0)
inner join localitygroup lg on (lg.id = hlg.id)
where misc.lifecyclestate <> 'deleted'
and (lg.fieldlocstate = 'CA' or lg.fieldlocstate = 'Baja California')
and o.numbervalue is not null
and o.numbervalue != ''
and substring(co.objectnumber from '^[A-Z]*') not in ('DHN', 'GOD', 'UCSB', 'UCSC');

\copy (select * from tmp_cch_annovouchers order by AccessionNumber, VoucherKind) to '$CCH_DIR/cch_annovouchers.txt' with null as ''

create temp table tmp_cch_othervouchers as
select
	co.objectnumber as AccessionNumber,
	hcoc.name as CSID,
	'comment' as NoteType,
	item as Note
from collectionobjects_common co
inner join hierarchy hcoc on (co.id = hcoc.id)
inner join hierarchy hlg
	on (co.id = hlg.parentid
	and hlg.name = 'collectionobjects_naturalhistory:localityGroupList'
	and hlg.pos = 0)
inner join localitygroup lg on lg.id = hlg.id
inner join collectionobjects_common_comments cc on cc.id = co.id
where (lg.fieldlocstate = 'CA' or lg.fieldlocstate = 'Baja California')
and substring(co.objectnumber from '^[A-Z]*') not in ('DHN', 'GOD', 'UCSB', 'UCSC')
and item <> '' and item is not null
union
select
	co.objectnumber as AccessionNumber,
	hcoc.name as CSID,
	'brief description' as NoteType,
	item as Note
from collectionobjects_common co
inner join hierarchy hcoc on (co.id = hcoc.id)
inner join hierarchy hlg
	on (co.id = hlg.parentid
	and hlg.name = 'collectionobjects_naturalhistory:localityGroupList'
	and hlg.pos = 0)
inner join localitygroup lg on lg.id = hlg.id
inner join collectionobjects_common_briefdescriptions cb on cb.id = co.id
where (lg.fieldlocstate = 'CA' or lg.fieldlocstate = 'Baja California')
and substring(co.objectnumber from '^[A-Z]*') not in ('DHN', 'GOD', 'UCSB', 'UCSC')
and item <> '' and item is not null
union
select
	co.objectnumber as AccessionNumber,
	hcoc.name as CSID,
	'habitat' as NoteType,
	fieldcollectionnote as Note
from collectionobjects_common co
inner join hierarchy hcoc on (co.id = hcoc.id)
inner join hierarchy hlg
	on (co.id = hlg.parentid
	and hlg.name = 'collectionobjects_naturalhistory:localityGroupList'
	and hlg.pos = 0)
inner join localitygroup lg on lg.id = hlg.id
where (lg.fieldlocstate = 'CA' or lg.fieldlocstate = 'Baja California')
and substring(co.objectnumber from '^[A-Z]*') not in ('DHN', 'GOD', 'UCSB', 'UCSC')
and fieldcollectionnote <> ''
and fieldcollectionnote is not null;

\copy (select * from tmp_cch_othervouchers order by AccessionNumber, NoteType) to '$CCH_DIR/cch_othervouchers.txt' with null as ''

create temp table tmp_cch_hybridparents as
select
	co.objectnumber as AccessionNumber,
	hcoc.name as CSID,
	hhpg.pos as Position,
	regexp_replace(hybridparent, '^.*\)''(.*)''$', '\1') as HybridParentName,
	hybridparentqualifier as HybridParentQualifier
from hybridparentgroup hpg
inner join hierarchy hhpg on (hhpg.id = hpg.id and primarytype = 'hybridParentGroup')
inner join collectionobjects_common co on co.id = hhpg.parentid
inner join hierarchy hcoc on (co.id = hcoc.id)
where hybridparent is not null and hybridparent <> ''
and substring(co.objectnumber from '^[A-Z]*') not in ('DHN', 'GOD', 'UCSB', 'UCSC');

\copy (select * from tmp_cch_hybridparents order by AccessionNumber, Position) to '$CCH_DIR/cch_hybridparents.txt' with null as ''
HP_END

ls -l $CCH_DIR >> $CCH_LOG

wc -l $CCH_DIR/* >> $CCH_LOG

tar -zcvf $CCH_DIR.tar.gz $CCH_DIR

ls -l $CCH_DIR.tar.gz >> $CCH_LOG

echo '' >> $CCH_LOG

