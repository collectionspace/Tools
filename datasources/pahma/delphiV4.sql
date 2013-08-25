SELECT

cc.id  ObjectID,
'' ObjectType,
'' CatRais,
'' Bibliography,
cc.objectnumber ObjectNumber,
(case when ong.objectName is NULL then '' else ong.objectName end) ObjectName,
'' Dated,
'' Title,

CASE WHEN (mat.material IS NOT NULL AND mat.material <> '') THEN
         regexp_replace(mat.material, '^.*\)''(.*)''$', '\1')
END AS Medium,

'' Dimensions,
''  Markings,
''  CuratorialRemarks,

case when (bd.item is not null and bd.item <> '') then
  regexp_replace(bd.item, '^.*\)''(.*)''$', '\1')
  else ''
end AS Description,

case when (pfc.item is not null and pfc.item <> '') then
 substring(pfc.item, position(')''' IN pfc.item)+2, LENGTH(pfc.item)-position(')''' IN pfc.item)-2)
end AS Provenance,

'' PubReferences,
''  Notes,
''  Edition,

case when (apg.assocpeople is not null and apg.assocpeople <> '') then
 substring(apg.assocpeople, position(')''' IN apg.assocpeople)+2, LENGTH(apg.assocpeople)-position(')''' IN apg.assocpeople)-2)
end as Culture,

'' Reign,

case when (pef.item is not null and pef.item <> '') then
 substring(pef.item, position(')''' IN pef.item)+2, LENGTH(pef.item)-position(')''' IN pef.item)-2)
end as Fabrication,

'' HiddenNotes,
'' OntoColor,
'' OntoCulture,
'' OntoDesignDecTech,
'' OntoLocation,
'' OntoMaterial,
'' OntoUseOrContext,

apg.assocpeople CultureRefname,
pfc.item ProvenanceRefname,
fieldCollectionNote,
regexp_replace(cc.computedcurrentlocation, '^.*\)''(.*)''$', '\1') Currentlocation,
ag.annotationnote annotationnote

FROM collectionobjects_common cc

left outer join hierarchy h4 on (cc.id = h4.parentid and h4.name =
'collectionobjects_common:objectNameList' and (h4.pos=0 or h4.pos is null))
left outer join objectnamegroup ong on (ong.id=h4.id)
left outer join annotationgroup ag on (ag.id = h4.id)

LEFT OUTER JOIN collectionobjects_common_briefdescriptions bd ON (bd.id=cc.id and bd.pos=0)

left outer join collectionobjects_anthropology ca on (ca.id=cc.id)
left outer join collectionobjects_pahma cp on (cp.id=cc.id)
left outer join collectionobjects_pahma_pahmafieldcollectionplacelist pfc on (pfc.id=cc.id AND (pfc.pos=0 or pfc.pos is null))
left outer join collectionobjects_pahma_pahmaethnographicfilecodelist pef on (pef.id=cc.id AND (pef.pos=0 or pef.pos is null))

left outer join hierarchy h5 on (cc.id=h5.parentid and h5.primarytype =
'assocPeopleGroup' and (h5.pos=0 or h5.pos is null))
left outer join assocpeoplegroup apg on (apg.id=h5.id)

LEFT OUTER JOIN hierarchy h6 ON (cc.id = h6.parentid AND h6.primarytype='materialGroup')
left outer join materialgroup mat on (mat.id=h6.id)
