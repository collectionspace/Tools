select opl.id, opl.collectionobjectcsid, opl.objectnumber,
       opl.numberofobjects, opl.placecsid, opl.placename,
       opl.csid_hierarchy as place_csid_hierarchy,
       opl.storagelocation, opl.crate,
       mh.csid_hierarchy as material_csid_hierarchy
from 
   utils.object_place_location opl
   join hierarchy h1
      on (opl.collectionobjectcsid = h1.name)
   join hierarchy h2
      on (h1.id = h2.parentid
          and
          h2.name = 'collectionobjects_common:materialGroupList')
   join materialgroup mg
      on (h2.id = mg.id)
   join concepts_common cnc
      on (mg.material = cnc.refname)
   join hierarchy h3
      on (cnc.id = h3.id)
   join utils.material_hierarchy mh
      on h3.name = mh.materialcsid
