SELECT
h1.name AS id,
h2.name AS objectid_s,
cc.objectnumber AS objectnumber_s,
mc.description AS description_s,
b.name AS name_s,
regexp_replace(mc.creator, '^.*\)''(.*)''$', '\1') AS creator_s,
mc.creator AS creatorrefname_s,
mc.blobcsid AS blob_ss,
mc.copyrightstatement AS copyrightstatement_s,
mc.identificationnumber AS identificationnumber_s,
regexp_replace(mc.rightsholder, '^.*\)''(.*)''$', '\1') AS rightsholder_s,
mc.rightsholder AS rightsholderrefname_s,
regexp_replace(mc.contributor, '^.*\)''(.*)''$', '\1') AS contributor_s,
mc.contributor AS contributorrefname_s,
regexp_replace(regexp_replace(mu.scientifictaxonomy, '^.*\)''(.*)''$', '\1'),E'[\\t\\n\\r]+', ' ', 'g') AS scientifictaxonomy_s,
regexp_replace(regexp_replace(tnh.family, '^.*\)''(.*)''$', '\1'),E'[\\t\\n\\r]+', ' ', 'g') AS family_s,
tu.taxonmajorgroup AS majorgroup_s,
mum.item AS morphologycategoryrefname_s,
regexp_replace(mum.item, '^.*\)''(.*)''$', '\1') AS morphologycategory_s,
mu.majorcategory AS majorcategoryrefname_s,
regexp_replace(mu.majorcategory, '^.*\)''(.*)''$', '\1') AS majorcategory_s,
mct.item AS typeofmedia_s,
regexp_replace(lg.fieldlocverbatim,E'[\\t\\n\\r]+', ' ', 'g') as locality_s,
dg.datedisplaydate as mediadate_s,
mu.posttopublic AS posttopublic_s,
mu.handwritten AS handwritten_s,
mu.collector AS collector_s,
lg.fieldLocState AS fieldLocState_s,
lg.fieldLocCountry AS fieldLocCountry_s,
lg.fieldLocCounty AS fieldLocCounty_s

FROM media_common mc

JOIN media_ucjeps mu on (mc.id=mu.id and mu.posttopublic !='no')
JOIN misc ON (mc.id = misc.id AND misc.lifecyclestate <> 'deleted')
LEFT OUTER JOIN hierarchy h1 ON (h1.id = mc.id)
LEFT OUTER JOIN relations_common r on (h1.name = r.objectcsid)
LEFT OUTER JOIN hierarchy h2 on (r.subjectcsid = h2.name)
LEFT OUTER JOIN collectionobjects_common cc on (h2.id = cc.id)
LEFT OUTER JOIN collectionobjects_ucjeps cop on (h2.id = cop.id)

LEFT OUTER JOIN hierarchy hsdg
        on (mc.id = hsdg.parentid and hsdg.name = 'media_common:dateGroupList' and hsdg.pos = 0)
-- nb: should be structureddategroup, but for some reason it isn't
LEFT OUTER JOIN dategroup dg on (dg.id = hsdg.id)

LEFT OUTER JOIN media_common_typelist mct on (mct.id = mc.id and mct.pos = 0)
LEFT OUTER JOIN media_ucjeps_morphologycategories mum on (mum.id = mc.id and mum.pos = 0)

LEFT OUTER JOIN taxon_common tc on (mu.scientifictaxonomy = tc.refname)
LEFT OUTER JOIN taxon_ucjeps tu on (tu.id = tc.id)
LEFT OUTER JOIN taxon_naturalhistory tnh on (tnh.id = tc.id)
LEFT OUTER JOIN hierarchy hlg
        on (mu.id = hlg.parentid and hlg.pos = 0
        and hlg.name = 'media_ucjeps:localityGroupList')
LEFT OUTER JOIN localitygroup lg on (lg.id = hlg.id)

JOIN hierarchy h3 ON (mc.blobcsid = h3.name)
LEFT OUTER JOIN blobs_common b on (h3.id = b.id)

WHERE mct.item IN ('Digital Image','Slide (Photograph)');
