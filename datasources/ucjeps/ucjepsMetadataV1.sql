select
    co.id as CSID,
    co.objectnumber as AccessionNumber,
    case when (tig.taxon is not null and tig.taxon <> '')
                then regexp_replace(tig.taxon, '^.*\)''(.*)''$', '\1')
    end as Determination,
    tu.taxonmajorgroup as MajorGroup,
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
    lg.coorduncertaintyunit as CoordinateUncertaintyUnit
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
left outer join taxon_common tc on (tig.taxon = tc.refname)
left outer join taxon_ucjeps tu on (tu.id = tc.id)
left outer join localitygroup lg on (lg.id = hlg.id)
where misc.lifecyclestate <> 'deleted'
-- and lg.fieldlocstate = 'CA'
and substring(co.objectnumber from '^[A-Z]*') in ('UC', 'UCLA', 'JEPS')
order by co.objectnumber
