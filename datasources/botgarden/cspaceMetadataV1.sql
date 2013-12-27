select
    co.id as CSID,
    co.objectnumber as AccessionNumber,
    case when (tig.taxon is not null and tig.taxon <> '')
                then regexp_replace(tig.taxon, '^.*\)''(.*)''$', '\1')
    end as Determination,
    case when (fc.item is not null and fc.item <> '')
                then regexp_replace(fc.item, '^.*\)''(.*)''$', '\1')
    end as Collector,
    co.fieldcollectionnumber as CollectorNumber,
    sdg.datedisplaydate as CollectionDate,
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
    end as EarlyCollectionDate,
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
    end as LateCollectionDate,
    lg.fieldlocverbatim as Locality,
    lg.fieldloccounty as CollCounty,
-- adding state and country
    lg.fieldlocstate as CollState,
    lg.fieldloccountry as CollCountry,
    lg.velevation as Elevation,
    lg.minelevation as MinElevation,
    lg.maxelevation as MaxElevation,
    lg.elevationunit as ElevationUnit,
        co.fieldcollectionnote as Habitat,
    lg.decimallatitude as DecLatitude,
    lg.decimallongitude as DecLongitude,
    case when lg.vcoordsys like 'Township%'
                then lg.vcoordinates
    end as TRSCoordinates,
    lg.geodeticdatum as Datum,
    lg.localitysource as CoordinateSource,
    lg.coorduncertainty as CoordinateUncertainty,
    lg.coorduncertaintyunit as CoordinateUncertaintyUnit,
    
case when (tn.family is not null and tn.family <> '')
     then regexp_replace(tn.family, '^.*\)''(.*)''$', '\1')
end as family,
case when (mc.currentlocation is not null and mc.currentlocation <> '')
     then regexp_replace(mc.currentlocation, '^.*\)''(.*)''$', '\1')
end as gardenlocation,
co.recordstatus dataQuality,
case when (lg.fieldlocplace is not null and lg.fieldlocplace <> '') then regexp_replace(lg.fieldlocplace, '^.*\)''(.*)''$', '\1')
     when (lg.fieldlocplace is null and lg.taxonomicrange is not null) then 'Geographic range: '||lg.taxonomicrange
end as locality,
h1.name as objectcsid,
con.rare,
cob.deadflag,
regexp_replace(tig2.taxon, '^.*\)''(.*)''$', '\1') as determinationNoAuth,
mc.reasonformove

from collectionobjects_common co
inner join misc on co.id = misc.id
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

join hierarchy h1 on co.id=h1.id
join relations_common r1 on (h1.name=r1.subjectcsid and objectdocumenttype='Movement')
join hierarchy h2 on (r1.objectcsid=h2.name and h2.isversion is not true)
join movements_common mc on (mc.id=h2.id)
join misc misc1 on (misc1.id = mc.id and misc1.lifecyclestate <> 'deleted') -- movement not deleted

join collectionobjects_naturalhistory con on (co.id = con.id)
join collectionobjects_botgarden cob on (co.id=cob.id)

left outer join hierarchy htig2
     on (co.id = htig2.parentid and htig2.pos = 1 and htig2.name = 'collectionobjects_naturalhistory:taxonomicIdentGroupList')
left outer join taxonomicIdentGroup tig2 on (tig2.id = htig2.id)

join collectionspace_core core on (core.id=co.id and core.tenantid=35)
join misc misc2 on (misc2.id = co.id and misc2.lifecyclestate <> 'deleted') -- object not deleted

left outer join taxon_common tc on (tig.taxon=tc.refname)
left outer join taxon_naturalhistory tn on (tc.id=tn.id) 