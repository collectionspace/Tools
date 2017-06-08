-- bampfa_metadata_v.sql
-- View used to provide object metadata to be harvested by Piction over stunnel to materialized view separate piction_transit instance (piction.bampfa_metadata_mv)
-- 10/27/2015 created script, changing query to not use other view, and changed separator to semi-colon
-- 8/7/2016 incorporated Lam's changes per BAMPFA-465 and fix to artistorigin per BAMPFA-495


create or replace view piction.bampfa_metadata_v as
 SELECT h1.name AS objectcsid,
    co.objectnumber AS idnumber,
    cb.sortableeffectiveobjectnumber AS sortobjectnumber,
        CASE
            WHEN cb.artistdisplayoverride IS NULL OR cb.artistdisplayoverride::text = ''::text THEN utils.concat_artists(h1.name)
            ELSE cb.artistdisplayoverride
        END AS artistcalc,
        CASE
            WHEN pc.birthplace IS NULL OR pc.birthplace::text = ''::text THEN pcn.item::text
            WHEN (pcn.item::text = pc.birthplace::text) then pcn.item::text
            ELSE (pcn.item::text || ', born '::text) || pc.birthplace::text
        END AS artistorigin,
    bt.bampfatitle AS title,
    sdg.datedisplaydate AS datemade,
        CASE
            WHEN pp.objectproductionplace IS NOT NULL AND pp.objectproductionplace::text <> ''::text THEN pp.objectproductionplace
            ELSE NULL::character varying
        END AS site,
    utils.getdispl(cb.itemclass::text) AS itemclass,
    co.physicaldescription AS materials,
    replace(mp.dimensionsummary::text, '-'::text, ' '::text) AS measurement,
        CASE
            WHEN cb.creditline::text = ''::text OR cb.creditline IS NULL THEN 'University of California, Berkeley Art Museum and Pacific Film Archive'::text
            ELSE 'University of California, Berkeley Art Museum and Pacific Film Archive; '::text || cb.creditline::text
        END AS fullbampfacreditline,
        CASE
            WHEN cb.copyrightcredit IS NULL OR cb.copyrightcredit::text = ''::text THEN pb.copyrightcredit
            ELSE cb.copyrightcredit
        END AS copyrightcredit,
    cb.photocredit,
    concat_ws('; '::text, utils.getdispl(st1.item::text), utils.getdispl(st2.item::text), utils.getdispl(st3.item::text), utils.getdispl(st4.item::text), utils.getdispl(st5.item::text)) AS subjects, concat_ws('; '::text, utils.getdispl(col1.item::text), utils.getdispl(col2.item::text), utils.getdispl(col3.item::text)) AS collections,
    concat_ws('; '::text, utils.getdispl(ps1.item::text), utils.getdispl(ps2.item::text), utils.getdispl(ps3.item::text), utils.getdispl(ps4.item::text), utils.getdispl(ps5.item::text)) AS periodstyles,
    concat_ws('-'::text, sdgpb.datedisplaydate,
         CASE
             WHEN sdgpd.datedisplaydate::text = ''::text THEN NULL::character varying
             ELSE sdgpd.datedisplaydate
         END) AS artistdates,
    '' AS caption,
    '' AS tags,
         CASE
             WHEN cb.permissiontoreproduce IS NULL OR cb.permissiontoreproduce::text = ''::text THEN 'Unknown'::character varying
             ELSE cb.permissiontoreproduce
         END AS permissiontoreproduce,
    cas.item AS acquisitionsource,
    utils.getdispl(cb.legalstatus::text) AS legalstatus,
    core.updatedat
   FROM hierarchy h1
     JOIN collectionobjects_common co ON h1.id::text = co.id::text AND h1.primarytype::text = 'CollectionObjectTenant55'::text
     JOIN misc m ON co.id::text = m.id::text AND m.lifecyclestate::text <> 'deleted'::text
     JOIN collectionobjects_bampfa cb ON co.id::text = cb.id::text
     JOIN collectionspace_core core ON co.id::text = core.id::text
     LEFT JOIN hierarchy h2 ON h2.parentid::text = co.id::text AND h2.name::text = 'collectionobjects_common:objectProductionDateGroupList'::text AND h2.pos = 0
     LEFT JOIN structureddategroup sdg ON h2.id::text = sdg.id::text
     LEFT JOIN hierarchy h4 ON h4.parentid::text = co.id::text AND h4.name::text = 'collectionobjects_bampfa:bampfaTitleGroupList'::text AND h4.pos = 0
     LEFT JOIN bampfatitlegroup bt ON h4.id::text = bt.id::text
     LEFT JOIN hierarchy h7 ON h7.parentid::text = co.id::text AND h7.name::text = 'collectionobjects_common:measuredPartGroupList'::text AND h7.pos = 0
     LEFT JOIN measuredpartgroup mp ON h7.id::text = mp.id::text
     LEFT JOIN collectionobjects_bampfa_acquisitionsources cas ON co.id::text = cas.id::text AND cas.pos = 0
     LEFT JOIN hierarchy h11 ON h11.parentid::text = co.id::text AND h11.name::text = 'collectionobjects_bampfa:bampfaObjectProductionPersonGroupList'::text AND h11.pos = 0
     LEFT JOIN bampfaobjectproductionpersongroup ba ON h11.id::text = ba.id::text
     LEFT JOIN persons_common pc ON ba.bampfaobjectproductionperson::text = pc.refname::text
     LEFT JOIN persons_common_nationalities pcn ON pc.id::text = pcn.id::text AND pcn.pos = 0
     LEFT JOIN hierarchy h12 ON h12.parentid::text = pc.id::text AND h12.name::text = 'persons_common:birthDateGroup'::text
     LEFT JOIN structureddategroup sdgpb ON h12.id::text = sdgpb.id::text
     LEFT JOIN hierarchy h13 ON h13.parentid::text = pc.id::text AND h13.name::text = 'persons_common:deathDateGroup'::text
     LEFT JOIN structureddategroup sdgpd ON h13.id::text = sdgpd.id::text
     LEFT JOIN persons_bampfa pb ON pc.id::text = pb.id::text
     LEFT JOIN hierarchy h14 ON h14.parentid::text = co.id::text AND h14.name::text = 'collectionobjects_common:objectProductionPlaceGroupList'::text AND h14.pos = 0
     LEFT JOIN objectproductionplacegroup pp ON h14.id::text = pp.id::text
     LEFT JOIN collectionobjects_bampfa_subjectthemes st1 ON st1.id::text = co.id::text AND st1.pos = 0
     LEFT JOIN collectionobjects_bampfa_subjectthemes st2 ON st2.id::text = co.id::text AND st2.pos = 1
     LEFT JOIN collectionobjects_bampfa_subjectthemes st3 ON st3.id::text = co.id::text AND st3.pos = 2
     LEFT JOIN collectionobjects_bampfa_subjectthemes st4 ON st4.id::text = co.id::text AND st4.pos = 3
     LEFT JOIN collectionobjects_bampfa_subjectthemes st5 ON st5.id::text = co.id::text AND st5.pos = 4
     LEFT JOIN collectionobjects_bampfa_bampfacollectionlist col1 ON col1.id::text = co.id::text AND col1.pos = 0
     LEFT JOIN collectionobjects_bampfa_bampfacollectionlist col2 ON col2.id::text = co.id::text AND col2.pos = 1
     LEFT JOIN collectionobjects_bampfa_bampfacollectionlist col3 ON col3.id::text = co.id::text AND col2.pos = 2
     LEFT JOIN collectionobjects_common_styles ps1 ON ps1.id::text = co.id::text AND ps1.pos = 0
     LEFT JOIN collectionobjects_common_styles ps2 ON ps2.id::text = co.id::text AND ps2.pos = 1
     LEFT JOIN collectionobjects_common_styles ps3 ON ps3.id::text = co.id::text AND ps3.pos = 2
     LEFT JOIN collectionobjects_common_styles ps4 ON ps4.id::text = co.id::text AND ps4.pos = 3
     LEFT JOIN collectionobjects_common_styles ps5 ON ps5.id::text = co.id::text AND ps5.pos = 4
-- where co.objectnumber like '2001%' 
  ORDER BY cb.sortableeffectiveobjectnumber;

grant all privileges on piction.bampfa_metadata_v to piction;
grant select on piction.bampfa_metadata_v to reporter_bampfa;
grant select on piction.bampfa_metadata_v to reader_bampfa;
grant select on piction.bampfa_metadata_v to piction_ro;
