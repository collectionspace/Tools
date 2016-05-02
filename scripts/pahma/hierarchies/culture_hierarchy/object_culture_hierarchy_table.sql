DROP TABLE IF EXISTS utils.object_culture_hierarchy;

select opl.id, opl.collectionobjectcsid,
       ch.culture,
       ch.culturecsid,
       ch.csid_hierarchy as culture_csid_hierarchy
into utils.object_culture_hierarchy
from
   utils.object_place_location opl
   join hierarchy h1
      on (opl.collectionobjectcsid = h1.name)
   join hierarchy h2
      on (h1.id = h2.parentid
          and
          h2.name = 'collectionobjects_common:assocCulturalContextGroupList')
   join assocculturalcontextgroup acg
      on (h2.id = acg.id)
   join concepts_common cnc
      on (acg.assocculturalcontext = cnc.refname)
   join hierarchy h3
      on (acg.id = h3.id)
   join utils.culture_hierarchy ch
      on h3.name = ch.culturecsid

