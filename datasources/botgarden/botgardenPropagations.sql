SELECT

pag.id as id,
cc.id as objid,
pc.id as pcid,

cc.objectnumber,

pc.propnumber,
pag.order,

pag.conditions,
pag.nurserylocation,
pag.activitycomments,
pag.potsize,
pag.chemicalapplied,
pag.activityconcentration,
pag.activitytype,
pag.medium,
pag.propcount,

pc.propcomments,
pc.numstarted,
pc.extraseeds,
pc.spores,
pc.successrate,
pc.planttype,
pc.concentration,
pc.germinationdate,
pc.wounded,
pc.hormone,
regexp_replace(pc.proptype, '^.*\)''(.*)''$', '\1') as proptype,
regexp_replace(pc.cuttingtype, '^.*\)''(.*)''$', '\1') as cuttingtype,
pc.propreason,

sdg.datedisplaydate as propdate


FROM propagations_common pc 

JOIN hierarchy h3 ON (h3.id = pc.id)
JOIN relations_common rc ON (rc.subjectcsid = h3.name AND rc.objectdocumenttype = 'CollectionObject')

JOIN hierarchy h4 ON (h4.name = rc.objectcsid)
JOIN collectionobjects_common cc ON (cc.id = h4.id)

JOIN hierarchy h1 ON (pc.id = h1.parentid AND h1.primarytype='propActivityGroup')
JOIN propactivitygroup pag ON (pag.id=h1.id)

LEFT OUTER JOIN hierarchy propdg ON (cc.id = propdg.parentid AND propdg.name = 'collectionobjects_common:fieldCollectionDateGroup')
LEFT OUTER JOIN structureddategroup sdg on (sdg.id = propdg.id)

JOIN misc ON (cc.id=misc.id)
WHERE misc.lifecyclestate <> 'deleted'
