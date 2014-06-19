SELECT cc.id, h1.name  AS "objcsid_txt", cp.sortableobjectnumber AS "objsortnum_txt",
cc.objectnumber AS "objmusno_txt", cp.pahmatmslegacydepartment AS "objdept_txt",
cc.collection AS "objtype_txt", cc.numberofobjects AS "objcount_txt", cp.inventorycount AS "objcountnote_txt",
cp.portfolioseries AS "objkeelingser_txt", cp.pahmafieldlocverbatim AS "objfcpverbatim_txt"
FROM collectionobjects_common cc
JOIN hierarchy h1 ON (h1.id=cc.id)
JOIN collectionobjects_pahma cp ON (cp.id=cc.id)
JOIN misc ON (cc.id=misc.id and misc.lifecyclestate <>'deleted')