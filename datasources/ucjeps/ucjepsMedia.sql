SELECT 
h2.name objectcsid,
cc.objectnumber,
h1.name mediacsid,
mc.description,
b.name,
mc.creator creatorRefname,
regexp_replace(mc.creator, '^.*\)''(.*)''$', '\1') creator,
mc.blobcsid,
mc.copyrightstatement,
mc.identificationnumber,
mc.rightsholder rightsholderRefname,
regexp_replace(mc.rightsholder, '^.*\)''(.*)''$', '\1') rightsholder,
mc.contributor

FROM media_common mc

JOIN media_ucjeps mu on (mc.id=mu.id and mu.posttopublic='yes')
JOIN misc ON (mc.id = misc.id AND misc.lifecyclestate <> 'deleted')
LEFT OUTER JOIN hierarchy h1 ON (h1.id = mc.id)
INNER JOIN relations_common r on (h1.name = r.objectcsid)
LEFT OUTER JOIN hierarchy h2 on (r.subjectcsid = h2.name)
LEFT OUTER JOIN collectionobjects_common cc on (h2.id = cc.id)
LEFT OUTER JOIN collectionobjects_ucjeps cop on (h2.id = cop.id)

JOIN hierarchy h3 ON (mc.blobcsid = h3.name)
LEFT OUTER JOIN blobs_common b on (h3.id = b.id);
