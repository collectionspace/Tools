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
mc.contributor AS contributorrefname_s

FROM media_common mc

-- JOIN media_ucjeps mu on (mc.id=mu.id and mu.posttopublic='yes')
JOIN media_ucjeps mu on (mc.id=mu.id)
JOIN misc ON (mc.id = misc.id AND misc.lifecyclestate <> 'deleted')
LEFT OUTER JOIN hierarchy h1 ON (h1.id = mc.id)
JOIN relations_common r on (h1.name = r.objectcsid)
LEFT OUTER JOIN hierarchy h2 on (r.subjectcsid = h2.name)
LEFT OUTER JOIN collectionobjects_common cc on (h2.id = cc.id)
LEFT OUTER JOIN collectionobjects_ucjeps cop on (h2.id = cop.id)

JOIN hierarchy h3 ON (mc.blobcsid = h3.name)
LEFT OUTER JOIN blobs_common b on (h3.id = b.id);
