select
    h1.name as csid_s,
    co.objectnumber as accessionnumber_s,
    case when (tig.taxon is not null and tig.taxon <> '')
                then regexp_replace(regexp_replace(tig.taxon, '^.*\)''(.*)''$', '\1'),E'[\\t\\n\\r]+', ' ', 'g')
    end as determination_s,
    ttg.termformatteddisplayname as termformatteddisplayname_s,
    regexp_replace(regexp_replace(tnh.family, '^.*\)''(.*)''$', '\1'),E'[\\t\\n\\r]+', ' ', 'g') as family_s,
    tnh.taxonbasionym as taxonbasionym_s,
    tu.taxonmajorgroup as majorgroup_s,
    case when (fc.item is not null and fc.item <> '')
                then regexp_replace(regexp_replace(fc.item, '^.*\)''(.*)''$', '\1'),E'[\\t\\n\\r]+', ' ', 'g')
    end as collector_ss,
    co.fieldcollectionnumber as collectornumber_s,
    sdg.datedisplaydate as collectiondate_s,
    case
        when
            sdg.dateearliestsingleyear != 0
            and sdg.dateearliestsinglemonth != 0
            and sdg.dateearliestsingleday != 0
        then
            to_date(
            sdg.dateearliestsingleyear::varchar(4) || '-' ||
            sdg.dateearliestsinglemonth::varchar(2) || '-' ||
            sdg.dateearliestsingleday::varchar(2),
            'yyyy-mm-dd')
        else null
    end as earlycollectiondate_dt,
    case
        when
            sdg.datelatestyear != 0
            and sdg.datelatestmonth != 0
            and sdg.datelatestday != 0
        then
            to_date(
            sdg.datelatestyear::varchar(4) || '-' ||
            sdg.datelatestmonth::varchar(2) || '-' ||
            sdg.datelatestday::varchar(2),
            'yyyy-mm-dd')
        else null
    end as latecollectiondate_dt,
    regexp_replace(lg.fieldlocverbatim,E'[\\t\\n\\r]+', ' ', 'g') as locality_s,
    lg.fieldloccounty as collcounty_s,
    lg.fieldlocstate as collstate_s,
    lg.fieldloccountry as collcountry_s,
    lg.velevation as elevation_s,
    lg.minelevation as minelevation_s,
    lg.maxelevation as maxelevation_s,
    lg.elevationunit as elevationunit_s,
    regexp_replace(co.fieldcollectionnote,E'[\\t\\n\\r]+', ' ', 'g') as habitat_s,
    lg.decimallatitude as location_0_coordinate,
    lg.decimallongitude as location_1_coordinate,
    lg.decimallatitude || ', ' || lg.decimallongitude as latlong_p,
    case when lg.vcoordsys like 'Township%'
                then lg.vcoordinates
    end as trscoordinates_s,
    lg.geodeticdatum as datum_s,
    lg.localitysource as coordinatesource_s,
    lg.coorduncertainty as coordinateuncertainty_f,
    lg.coorduncertaintyunit as coordinateuncertaintyunit_s,
    lg.localitynote as localitynote_s,
    lg.localitysource as localitysource_s,
    lg.localitysourcedetail as localitysourcedetail_s,
    cc.updatedat as updatedat_dt,
    case when conh.labelheader like 'urn:%' then getdispl(conh.labelheader)
        else conh.labelheader
    end as labelheader_s,
    case when conh.labelfooter like 'urn:%' then getdispl(conh.labelfooter)
        else conh.labelfooter
    end as labelfooter_s,
    array_to_string(array
      (SELECT
	CASE WHEN (tig2.qualifier IS NOT NULL AND tig2.qualifier <>'') THEN  '' || tig2.qualifier || ' ' ELSE '' END
  ||CASE WHEN (tig2.taxon IS NOT NULL AND tig2.taxon <>'' and tig2.taxon not like '%no name%') THEN (getdispl(tig2.taxon)
	||CASE WHEN (tig2.identby IS NOT NULL AND tig2.identby <>'' and tig2.identby not like '%unknown%') THEN ', by ' || getdispl(tig2.identby) ELSE '' END
	||CASE WHEN (tig2.institution IS NOT NULL AND tig2.institution <>'') THEN ', ' || getdispl(tig2.institution) ELSE '' END
	||CASE WHEN (prevdetsdg.datedisplaydate IS NOT NULL AND prevdetsdg.datedisplaydate <>'' and prevdetsdg.datedisplaydate <>' ') THEN ', ' || prevdetsdg.datedisplaydate ELSE '' END
	||CASE WHEN (tig2.identkind IS NOT NULL AND tig2.identkind <>'') THEN  ' (' || tig2.identkind || ')'ELSE '' END) ELSE '' END
	||CASE WHEN (tig2.notes IS NOT NULL AND tig2.notes <>'') THEN  '. ' || tig2.notes ELSE '' END
       from collectionobjects_common co1
        inner join hierarchy h1int on co1.id = h1int.id
        left outer join hierarchy htig2 on (co1.id = htig2.parentid and htig2.pos > 0
        and htig2.name = 'collectionobjects_naturalhistory:taxonomicIdentGroupList')
        left outer join taxonomicIdentGroup tig2 on (tig2.id = htig2.id)
        left outer join hierarchy hprevdet on (tig2.id = hprevdet.parentid and hprevdet.name = 'identDateGroup')
        left outer join structureddategroup prevdetsdg on (prevdetsdg.id = hprevdet.id)
       where h1int.name=h1.name order by htig2.pos), '␥', '') previousdeterminations_ss,
    lng.localname as localname_s,
    case when cocbd.item is null or cocbd.item = '' then null else cocbd.item end as briefdescription_txt,
    lg.vdepth as depth_s,
    lg.mindepth as mindepth_s,
    lg.maxdepth as maxdepth_s,
    lg.depthunit as depthUnit_s,
    array_to_string(array
      (SELECT CASE WHEN (atg.associatedtaxon IS NOT NULL AND atg.associatedtaxon<>'') THEN (getdispl(atg.associatedtaxon)
	||CASE WHEN (atg.interaction IS NOT NULL AND atg.interaction<>'') THEN ' (' || atg.interaction||')' ELSE '' END) ELSE '' END
      from collectionobjects_common co4
      inner join hierarchy h4int on co4.id = h4int.id
      left outer join hierarchy hatg on (co4.id = hatg.parentid
        and hatg.name = 'collectionobjects_naturalhistory:associatedTaxaGroupList')
      left outer join associatedtaxagroup atg on (hatg.id = atg.id)
      where h4int.name = h1.name
      order by hatg.pos), '␥', '') as associatedtaxa_ss,
    array_to_string(array
      (SELECT CASE WHEN (tsg.typespecimenkind IS NOT NULL AND tsg.typespecimenkind <>'') THEN (tsg.typespecimenkind
	||CASE WHEN (tsg.typespecimenbasionym IS NOT NULL AND tsg.typespecimenbasionym <>'') THEN ' (' || getdispl(tsg.typespecimenbasionym)||')' ELSE '' END) ELSE '' END
       from collectionobjects_common co2
       inner join hierarchy h2int on co2.id = h2int.id
       left outer join hierarchy htsg on (co2.id = htsg.parentid
        and htsg.name = 'collectionobjects_naturalhistory:typeSpecimenGroupList')
       left outer join typespecimengroup tsg on (tsg.id = htsg.id)
       where h2int.name = h1.name
       order by htsg.pos), '␥', '') as typeassertions_ss,
    case when conh.cultivated is null or conh.cultivated = '' then null else conh.cultivated end as Cultivated_s,
    case when co.sex is null or co.sex = '' then null else co.sex end as sex_s,
    co.phase as phase_s,
    array_to_string(array
      (SELECT CASE WHEN (ong.numbervalue IS NOT NULL AND ong.numbervalue<>'') THEN (ong.numbervalue
	||CASE WHEN (ong.numbertype IS NOT NULL AND ong.numbertype <>'') THEN ' (' || ong.numbertype||')' ELSE '' END) ELSE '' END
       from collectionobjects_common co3
       inner join hierarchy h3int on co3.id = h3int.id
       left outer join hierarchy hong on (co3.id = hong.parentid
         and hong.name = 'collectionobjects_common:otherNumberList')
       left outer join othernumber ong on (ong.id = hong.id)
       where h3int.name = h1.name
       order by hong.pos), '␥', '') as othernumber_ss,
    'ucbgacccession' as ucbgaccessionnumber_s,
    CASE WHEN (tig.identby IS NOT NULL AND tig.identby <>'' and tig.identby not like '%unknown%') THEN (getdispl(tig.identby)
	||CASE WHEN (tig.institution IS NOT NULL AND tig.institution <>'') THEN ', ' || getdispl(tig.institution) ELSE '' END
	||CASE WHEN (detdetailssdg.datedisplaydate IS NOT NULL AND detdetailssdg.datedisplaydate <>'' and detdetailssdg.datedisplaydate <>' ') THEN ', ' || detdetailssdg.datedisplaydate ELSE '' END
	||CASE WHEN (tig.identkind IS NOT NULL AND tig.identkind <>'') THEN ' (' || tig.identkind || ')' ELSE '' END
  ||CASE WHEN (tig.notes IS NOT NULL AND tig.notes <>'') THEN  '. ' || tig.notes ELSE '' END) ELSE '' END AS determinationdetails_s,
  '' as loanstatus_s,
  '' as loannumber_s,
    case when (fc.item is not null and fc.item <> '')
                then regexp_replace(regexp_replace(fc.item, '^.*\)''(.*)''$', '\1'),E'[\\t\\n\\r]+', ' ', 'g')
    end as collectorverbatim_s,
  array_to_string(array
      (SELECT CASE WHEN (lg2.fieldlocverbatim IS NOT NULL AND lg2.fieldlocverbatim <>'' and lg2.fieldlocverbatim not like '%unknown%') THEN (getdispl(lg2.fieldlocverbatim)) ELSE '' END
        from collectionobjects_common co5
	      inner join hierarchy h5int on co5.id = h5int.id
	      left outer join hierarchy hlg2 on (co5.id = hlg2.parentid and hlg2.pos > 0
	      and hlg2.name = 'collectionobjects_naturalhistory:localityGroupList')
	      left outer join localityGroup lg2 on (lg2.id = hlg2.id)
        where h5int.name=h1.name order by hlg2.pos), '␥', '') as otherlocalities_ss,
  array_to_string(array
      (SELECT CASE WHEN (lg2.fieldlocverbatim IS NOT NULL AND lg2.fieldlocverbatim <>'' and lg2.fieldlocverbatim not like '%unknown%') THEN (getdispl(lg2.fieldlocverbatim)) ELSE '' END
        from collectionobjects_common co5
	      inner join hierarchy h5int on co5.id = h5int.id
	      left outer join hierarchy hlg2 on (co5.id = hlg2.parentid and hlg2.pos >= 0
	      and hlg2.name = 'collectionobjects_naturalhistory:localityGroupList')
	      left outer join localityGroup lg2 on (lg2.id = hlg2.id)
        where h5int.name=h1.name order by hlg2.pos), '␥', '') as alllocalities_ss,
  CASE WHEN (tsg.typespecimenbasionym IS NOT NULL AND tsg.typespecimenbasionym <>'') THEN 'yes' ELSE 'no' END as hastypeassertions_s,
  tig.qualifier as determinationqualifier_s,
  com.item AS comments_ss

from collectionobjects_common co
inner join misc on (co.id = misc.id and misc.lifecyclestate <> 'deleted')
inner join hierarchy h1 on co.id = h1.id
inner join collectionspace_core cc on co.id=cc.id
left outer join collectionobjects_common_fieldCollectors fc
        on (co.id = fc.id and fc.pos = 0)
left outer join hierarchy hfcdg
        on (co.id = hfcdg.parentid and hfcdg.name = 'collectionobjects_common:fieldCollectionDateGroup')
left outer join structureddategroup sdg on (sdg.id = hfcdg.id)
left outer join hierarchy htig
        on (co.id = htig.parentid and htig.pos = 0
        and htig.name = 'collectionobjects_naturalhistory:taxonomicIdentGroupList')
left outer join taxonomicIdentGroup tig on (tig.id = htig.id)
left outer join hierarchy hdetdetailsdate on (tig.id = hdetdetailsdate.parentid and hdetdetailsdate.name = 'identDateGroup')
left outer join structureddategroup detdetailssdg on (detdetailssdg.id = hdetdetailsdate.id)
left outer join hierarchy hlg
        on (co.id = hlg.parentid and hlg.pos = 0
        and hlg.name = 'collectionobjects_naturalhistory:localityGroupList')
left outer join taxon_common tc on (tig.taxon = tc.refname)
left outer join hierarchy httg on (
    tc.id = httg.parentid
    and httg.name = 'taxon_common:taxonTermGroupList'
    and httg.pos = 0)
left outer join collectionobjects_common_comments com ON (com.id = cc.id and com.pos = 0)

inner join hierarchy h2int on co.id = h2int.id and h2int.name = h1.name
left outer join hierarchy htsg on (co.id = htsg.parentid and htsg.pos = 0
    and htsg.name = 'collectionobjects_naturalhistory:typeSpecimenGroupList')
left outer join typespecimengroup tsg on (tsg.id = htsg.id)

left outer join taxontermgroup ttg on (ttg.id = httg.id)
left outer join taxon_ucjeps tu on (tu.id = tc.id)
left outer join taxon_naturalhistory tnh on (tnh.id = tc.id)
left outer join localitygroup lg on (lg.id = hlg.id)
left outer join collectionobjects_naturalhistory conh on (co.id = conh.id)
left outer join hierarchy hlng on (co.id = hlng.parentid and hlng.primarytype = 'localNameGroup' and hlng.pos = 0)
left outer join localNameGroup lng on (hlng.id = lng.id)
left outer join collectionobjects_common_briefdescriptions cocbd on (co.id = cocbd.id and cocbd.pos = 0)
where substring(co.objectnumber from '^[A-Z]*') not in ('DHN', 'UCSB', 'UCSC')
-- and h1.name = '3380bad9-5bea-4eed-860e' -- UCcrhtest on ucjeps-dev
-- and h1.name = '338075de-821c-49b3-8f34-969cc666a61e' -- JEPS46872
-- and h1.name = '291d85e2-06dc-4fc2-9364' -- UC1300355
-- and h1.name = '33803cfe-e6a8-4025-bf53-a3814cf4da82'	-- JEPS105623
-- and h1.name like '3380%'
-- and h1.name = '0ad96db0-be78-4a0b-8f99-9fb229222ffb'	-- JEPS70526
