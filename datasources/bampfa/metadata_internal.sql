select
   h1.name objectCSID,
   co.objectnumber idNumber,
   cb.sortableEffectiveObjectNumber sortObjectNumber,
   con.numbervalue otherNumber,
   utils.getdispl(cb.itemclass) itemclass,
   utils.concat_artists(h1.name) artistCalc,
--   getdispl(ba.bampfaobjectproductionperson) artist,
   case
     when (pc.birthplace is null or pc.birthplace='') then pcn.item
     when (pcn.item = pc.birthplace) then pcn.item
     else pcn.item||', born '||pc.birthplace end
   as artistorigin,
   sdgpb.datedisplaydate artistbirthdate,
   sdgpd.datedisplaydate artistdeathdate,
   pb.datesactive,
   bt.bampfatitle title,
   -- not included, for now
   -- cb.initialvalue,
   -- cv.currentvalue,
   '-REDACTED-' as initialvalue,
   '-REDACTED-' as currentvalue,
   cv.currentvaluesource,
   sdgcv.datedisplaydate currentvaluedate,
   cb.creditline, 
   case when (cb.creditline='' or cb.creditline is null)  then
     'University of California, Berkeley Art Museum and Pacific Film Archive'
     else 'University of California, Berkeley Art Museum and Pacific Film Archive; '||cb.creditline
   end as fullBAMPFAcreditline,
   case when (cb.permissiontoreproduce is null or cb.permissiontoreproduce='') then pb.permissiontoreproduce
      else cb.permissiontoreproduce end as permissiontoreproduce,
   case when (cb.copyrightCredit is null or cb.copyrightCredit='') then pb.copyrightCredit
      else cb.copyrightCredit end as copyrightCredit,
   cb.photoCredit,
   sdg.datedisplaydate dateMade,
   replace(mp.dimensionsummary, '-', ' ') measurement,
   co.physicaldescription materials,
   sdgac.datedisplaydate dateacquired, -- in future will need case statements to get from intake
   cas.item acquisitionsource,
   cb.provenance,
   sg.inscriptioncontent signature,
   ccom.item notescomments,
   cg.catalogername cataloger,
   cg.catalognote catalognote,
   cg.catalogdate,
   apg.assocplace site,
   utils.getdispl(st1.item) SubjectOne,
   utils.getdispl(st2.item) SubjectTwo,
   utils.getdispl(st3.item) SubjectThree,
   utils.getdispl(st4.item) SubjectFour,
   utils.getdispl(st5.item) SubjectFive,
   utils.getdispl(co.computedcurrentlocation) currentlocation,
   utils.getdispl(cb.computedcrate) currentcrate,
   TRIM(cb.objectProductionDateCentury || ' ' || regexp_replace(cb.objectProductionDateEra, '^.*\)''(.*)''$', '\1')) as century,
   array_to_string(array
      (SELECT CASE WHEN (gc.title IS NOT NULL AND gc.title <> '') THEN (gc.title) END
       from collectionobjects_common co2
       inner join hierarchy h2int on co2.id = h2int.id
       join relations_common rc ON (h2int.name = rc.subjectcsid AND rc.objectdocumenttype = 'Group')
       join hierarchy h16 ON (rc.objectcsid = h16.name)
       left outer join groups_common gc ON (h16.id = gc.id)
       join misc mm ON (gc.id=mm.id AND mm.lifecyclestate <> 'deleted')
       where h2int.name = h1.name), ';', '') as grouptitle_ss
from
   hierarchy h1
   INNER JOIN collectionobjects_common co
      ON (h1.id = co.id AND h1.primarytype = 'CollectionObjectTenant55')
   INNER JOIN misc m
      ON (co.id = m.id AND m.lifecyclestate <> 'deleted')
   INNER JOIN collectionobjects_bampfa cb
      ON (co.id = cb.id)
   INNER JOIN collectionspace_core core on co.id=core.id
   LEFT OUTER JOIN hierarchy h2
      ON (h2.parentid = co.id AND h2.name='collectionobjects_common:objectProductionDateGroupList' and h2.pos=0)
   LEFT OUTER JOIN structuredDateGroup sdg ON (h2.id = sdg.id)
   LEFT OUTER JOIN hierarchy h3
      ON (h3.parentid = co.id AND h3.name = 'collectionobjects_common:otherNumberList' and h3.pos=0)
   LEFT OUTER JOIN othernumber con
      ON (h3.id = con.id)
   LEFT OUTER JOIN hierarchy h4
      ON (h4.parentid = co.id AND h4.name = 'collectionobjects_bampfa:bampfaTitleGroupList' and h4.pos=0)
   LEFT OUTER JOIN bampfatitlegroup bt
      ON (h4.id = bt.id)
   LEFT OUTER JOIN hierarchy h5
      ON (h5.parentid = co.id AND h5.name = 'collectionobjects_bampfa:currentValueGroupList' and h5.pos=0)
   LEFT OUTER JOIN currentvaluegroup cv
      ON (h5.id = cv.id)  
   LEFT OUTER JOIN hierarchy h6
      ON (h6.parentid = cv.id AND h6.name='currentValueDateGroup')
   LEFT OUTER JOIN structuredDateGroup sdgcv ON (h6.id = sdgcv.id)
   LEFT OUTER JOIN hierarchy h7
      ON (h7.parentid = co.id AND h7.name = 'collectionobjects_common:measuredPartGroupList' and h7.pos=0)
   LEFT OUTER JOIN measuredpartgroup mp
      ON (h7.id = mp.id)
   LEFT OUTER JOIN hierarchy h8
      ON (h8.parentid = co.id AND h8.name = 'collectionobjects_common:textualInscriptionGroupList' and h8.pos=0)
   LEFT OUTER JOIN textualinscriptiongroup sg
      ON (h8.id = sg.id)
   LEFT OUTER JOIN hierarchy h9
      ON (h9.parentid = co.id AND h9.name='collectionobjects_bampfa:acquisitionDateGroupList' and h9.pos=0)
   LEFT OUTER JOIN structuredDateGroup sdgac ON (h9.id = sdgac.id)
   LEFT OUTER JOIN collectionobjects_bampfa_acquisitionsources cas on (co.id=cas.id and cas.pos=0)
   LEFT OUTER JOIN collectionobjects_common_comments ccom on (co.id=ccom.id and ccom.pos=0)
   LEFT OUTER JOIN hierarchy h10
      ON (h10.parentid = co.id AND h10.name = 'collectionobjects_bampfa:catalogerGroupList' and h10.pos=0)
   LEFT OUTER JOIN catalogergroup cg
      ON (h10.id = cg.id)
   LEFT OUTER JOIN hierarchy h11
      ON (h11.parentid = co.id AND h11.name = 'collectionobjects_bampfa:bampfaObjectProductionPersonGroupList' and h11.pos=0)
   LEFT OUTER JOIN bampfaobjectproductionpersongroup ba
      ON (h11.id = ba.id)  
   LEFT OUTER JOIN persons_common pc on (ba.bampfaobjectproductionperson=pc.refname)
   LEFT OUTER JOIN persons_common_nationalities pcn on (pc.id=pcn.id and pcn.pos=0)
   LEFT OUTER JOIN hierarchy h12
      ON (h12.parentid = pc.id AND h12.name='persons_common:birthDateGroup')
   LEFT OUTER JOIN structuredDateGroup sdgpb ON (h12.id = sdgpb.id)
   LEFT OUTER JOIN hierarchy h13
      ON (h13.parentid = pc.id AND h13.name='persons_common:deathDateGroup')
   LEFT OUTER JOIN structuredDateGroup sdgpd ON (h13.id = sdgpd.id)
   LEFT OUTER JOIN persons_bampfa pb on (pc.id=pb.id)
   LEFT OUTER JOIN hierarchy h14
      ON (h14.parentid = co.id AND h14.name = 'collectionobjects_common:assocPlaceGroupList' and h14.pos=0)
   LEFT OUTER JOIN assocplacegroup apg
      ON (h14.id = apg.id)
   LEFT OUTER JOIN collectionobjects_bampfa_subjectthemes st1 ON (st1.id=co.id and st1.pos=0)
   LEFT OUTER JOIN collectionobjects_bampfa_subjectthemes st2 ON (st2.id=co.id and st2.pos=1)
   LEFT OUTER JOIN collectionobjects_bampfa_subjectthemes st3 ON (st3.id=co.id and st3.pos=2)
   LEFT OUTER JOIN collectionobjects_bampfa_subjectthemes st4 ON (st4.id=co.id and st4.pos=3)
   LEFT OUTER JOIN collectionobjects_bampfa_subjectthemes st5 ON (st5.id=co.id and st5.pos=4)
