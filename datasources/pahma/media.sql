SELECT 
h2.name objectcsid,
cc.objectnumber,
h1.name mediacsid,
mc.description,
b.name,
mc.creator creatorRefname,
mc.creator creator,
mc.blobcsid,
mc.copyrightstatement,
mc.identificationnumber,
mc.rightsholder rightsholderRefname,
mc.rightsholder rightsholder,
mc.contributor,
mp.approvedforweb

FROM media_common mc
JOIN media_pahma mp ON (mp.id = mc.id)

LEFT OUTER JOIN hierarchy h1 ON (h1.id = mc.id)
INNER JOIN relations_common r on (h1.name = r.objectcsid)
LEFT OUTER JOIN hierarchy h2 on (r.subjectcsid = h2.name)
LEFT OUTER JOIN collectionobjects_common cc on (h2.id = cc.id)
LEFT OUTER JOIN collectionobjects_pahma cop on (h2.id = cop.id)

JOIN hierarchy h3 ON (mc.blobcsid = h3.name)
LEFT OUTER JOIN blobs_common b on (h3.id = b.id);