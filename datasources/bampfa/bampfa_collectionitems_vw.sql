-- bampfa_collectionitems_vw.sql
-- View used to get live data in support of several functions, including Inject Metadata
-- CRH 10/22/2014
-- CRH 10/27/2014 Measurements subst hyphen with space. Utils schema.
-- CRH 11/25/2014 Added artistDisplayOverride
-- CRH 04/25/2015 Added several fields; see Jira BAMPFA-402
-- CRH 7/30/2015 Added Acquisition Method BAMPFA-446
-- LKV 9/28/2016 BAMPFA-507; Added call to new function utils.get_first_blobcsid_displevel to get
--     first image blob csid (image1blobcsid) and website display level (image1displevel) for all images.
-- LKV 10/27/2016 BAMPFA-512; Added new field 'image_count' using new function utils.get_object_image_count; dropped and recreated view.

-- drop view utils.bampfa_collectionitems_vw

create or replace view utils.bampfa_collectionitems_vw as
SELECT
   h1.name objectCSID,
   co.objectnumber idNumber,
   cb.sortableEffectiveObjectNumber sortObjectNumber,
   con.numbervalue otherNumber,
   utils.getdispl(cb.itemclass) itemclass,
   case when (cb.artistdisplayoverride is null or cb.artistdisplayoverride='') then utils.concat_artists(h1.name)
     else cb.artistdisplayoverride end as artistCalc,
   case
     when (pc.birthplace is null or pc.birthplace='') then pcn.item
     when (pcn.item = pc.birthplace) then pcn.item
     else pcn.item||', born '||pc.birthplace end
   as artistorigin,
   sdgpb.datedisplaydate artistbirthdate,
   sdgpd.datedisplaydate artistdeathdate,
   pb.datesactive,
   bt.bampfatitle title,
   cb.initialvalue,
   cv.currentvalue,
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
   case when (pp.objectproductionplace is not null and pp.objectproductionplace<>'') then pp.objectproductionplace
      else null
   end as site,
   utils.getdispl(st1.item) SubjectOne,
   utils.getdispl(st2.item) SubjectTwo,
   utils.getdispl(st3.item) SubjectThree,
   utils.getdispl(st4.item) SubjectFour,
   utils.getdispl(st5.item) SubjectFive,
   utils.getdispl(co.computedcurrentlocation) currentlocation,
   utils.getdispl(cb.computedcrate) currentcrate,
   utils.getdispl(col1.item) collection1,
   utils.getdispl(col2.item) collection2,
   utils.getdispl(col3.item) collection3,
   utils.getdispl(ps1.item) periodstyle1,
   utils.getdispl(ps2.item) periodstyle2,
   utils.getdispl(ps3.item) periodstyle3,
   utils.getdispl(ps4.item) periodstyle4,
   utils.getdispl(ps5.item) periodstyle5,
   utils.getdispl(cb.legalstatus) legalstatus,
   utils.get_object_image_count(h1.name) imagecount,
   utils.get_first_blobcsid_displevel(h1.name, 'blobcsid') image1blobcsid,
   utils.get_first_blobcsid_displevel(h1.name, 'displevel') image1displevel,
   utils.getdispl(cb.acquisitionmethod) acquisitionmethod
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
      ON (h14.parentid = co.id AND h14.name = 'collectionobjects_common:objectProductionPlaceGroupList' and h14.pos=0)
   LEFT OUTER JOIN objectproductionplacegroup pp
      ON (h14.id = pp.id)
   LEFT OUTER JOIN collectionobjects_bampfa_subjectthemes st1 ON (st1.id=co.id and st1.pos=0)
   LEFT OUTER JOIN collectionobjects_bampfa_subjectthemes st2 ON (st2.id=co.id and st2.pos=1)
   LEFT OUTER JOIN collectionobjects_bampfa_subjectthemes st3 ON (st3.id=co.id and st3.pos=2)
   LEFT OUTER JOIN collectionobjects_bampfa_subjectthemes st4 ON (st4.id=co.id and st4.pos=3)
   LEFT OUTER JOIN collectionobjects_bampfa_subjectthemes st5 ON (st5.id=co.id and st5.pos=4)
   LEFT OUTER JOIN collectionobjects_bampfa_bampfacollectionlist col1 ON (col1.id=co.id and col1.pos=0)
   LEFT OUTER JOIN collectionobjects_bampfa_bampfacollectionlist col2 ON (col2.id=co.id and col2.pos=1)
   LEFT OUTER JOIN collectionobjects_bampfa_bampfacollectionlist col3 ON (col3.id=co.id and col2.pos=2)
   LEFT OUTER JOIN collectionobjects_common_styles ps1 ON (ps1.id=co.id and ps1.pos=0)
   LEFT OUTER JOIN collectionobjects_common_styles ps2 ON (ps2.id=co.id and ps2.pos=1)
   LEFT OUTER JOIN collectionobjects_common_styles ps3 ON (ps3.id=co.id and ps3.pos=2)
   LEFT OUTER JOIN collectionobjects_common_styles ps4 ON (ps4.id=co.id and ps4.pos=3)
   LEFT OUTER JOIN collectionobjects_common_styles ps5 ON (ps5.id=co.id and ps5.pos=4)
order by cb.sortableEffectiveObjectNumber;

grant select on utils.bampfa_collectionitems_vw to reader_bampfa;
grant select on utils.bampfa_collectionitems_vw to group reporters_bampfa;
