SELECT cc.id, REGEXP_REPLACE(fcp.item, '^.*\)''(.*)''$', '\1') AS "objfcp_s",
geo.decimallatitude || ', ' || geo.decimallongitude AS "objfcpgeoloc_p",
pc.velevation AS "objfcpelevation_s",
utils.placename_hierarchy.place_hierarchy AS "objfcptree_s"
FROM collectionobjects_common cc
JOIN collectionobjects_pahma_pahmafieldcollectionplacelist fcp ON (fcp.id=cc.id AND (fcp.pos=0 OR fcp.pos IS NULL))
JOIN places_common pc ON (pc.shortidentifier=REGEXP_REPLACE(fcp.item, '^.*item:name\((.*)\)''.*', '\1'))
JOIN hierarchy pcsid ON (pc.id=pcsid.id)
LEFT OUTER JOIN utils.placename_hierarchy ON (pcsid.name=utils.placename_hierarchy.placecsid)
LEFT OUTER JOIN hierarchy hp ON (hp.parentid=pc.id AND hp.primarytype='placeGeoRefGroup' AND (hp.pos=0 OR hp.pos IS NULL))
LEFT OUTER JOIN placegeorefgroup geo ON (geo.id=hp.id)