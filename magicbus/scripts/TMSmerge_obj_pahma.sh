#!/bin/bash

# "XMLmerge" to get pahmaAltNum, objectName, briefDescription, objectTitle, ethnographicFileCode, 
# and FieldCollection (collector, note), ObjHist & Assoc (assocPerson/Org, prevOwner), Production (Person/Org/Date)
# 5/10 add personDepicted, conetentInscription, annotate, comment, materialNote, nagpraDetermination, repatriationNote, taxonNote
# Note: pending XMLmerge -- objAnnotations, FieldCollection (date, place), ObjHist & Assoc (assocPeople, assocDate), Production (date)
#       5/10 more pending -- more on content(Culture/Place depicted)
#            nagpraDetermination, repatriationNote so far don't have any repeated case, so may be able to merge into main "object" run

# THIS MERGING SCRIPT IS FOR PAHMA.CSPACE PRODUCTION --- 
# Note: All "delta" are from 2012-06-19 except objStatus which is from 2012-06-15
 
java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_pahma:pahmaAltNumGroupList TMSobj.2012-06-1970.xml obj_altNum.2012-06-19.xml /tmp/mrg01_altNum.2012-06-1970.xml 0 1 > mrg01_altNum.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:objectNameList /tmp/mrg01_altNum.2012-06-1970.xml obj_objName.2012-06-19.xml /tmp/mrg02_objName.2012-06-1970.xml 0 1 > mrg02_objName.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:briefDescriptions /tmp/mrg02_objName.2012-06-1970.xml obj_brfDESC.2012-06-19.xml /tmp/mrg03_brfDesc.2012-06-1970.xml 0 1 > mrg03_brfDesc.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:titleGroupList /tmp/mrg03_brfDesc.2012-06-1970.xml obj_objTtl.2012-06-19.xml /tmp/mrg04_objTtl.2012-06-1970.xml 0 1 > mrg04_objTtl.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_pahma:pahmaEthnographicFileCodeList /tmp/mrg04_objTtl.2012-06-1970.xml obj_ethnoFileCode.2012-06-19.xml /tmp/mrg05_ethnoFileCode.2012-06-1970.xml 0 1 > mrg05_ethnoFileCode.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:fieldCollectors /tmp/mrg05_ethnoFileCode.2012-06-1970.xml obj_fieldCollector.2012-06-19.xml /tmp/mrg06_fieldCollector.2012-06-1970.xml 0 1 > mrg06_fieldCollector.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:fieldCollectionNote /tmp/mrg06_fieldCollector.2012-06-1970.xml obj_fieldCollNote.2012-06-19.xml /tmp/mrg07_fieldCollNote.2012-06-1970.xml 0 1 > mrg07_fieldCollNote.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:assocOrganizationGroupList /tmp/mrg07_fieldCollNote.2012-06-1970.xml obj_assocOrg.2012-06-19.xml /tmp/mrg08_assocOrg.2012-06-1970.xml 0 1 > mrg08_assocOrg.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:assocPersonGroupList /tmp/mrg08_assocOrg.2012-06-1970.xml obj_assocPerson.2012-06-19.xml /tmp/mrg09_assocPerson.2012-06-1970.xml 0 1 > mrg09_assocPerson.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_pahma:ownershipHistoryGroupList /tmp/mrg09_assocPerson.2012-06-1970.xml obj_assocPrevOwner.2012-06-19.xml /tmp/mrg10_assocPrevOwner.2012-06-1970.xml 0 1 > mrg10_assocPrevOwner.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:objectProductionPersonGroupList /tmp/mrg10_assocPrevOwner.2012-06-1970.xml obj_prodPerson.2012-06-19.xml /tmp/mrg11_prodPerson.2012-06-1970.xml 0 1 > mrg11_prodPerson.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:objectProductionOrganizationGroupList /tmp/mrg11_prodPerson.2012-06-1970.xml obj_prodOrg.2012-06-19.xml /tmp/mrg12_prodOrg.2012-06-1970.xml 0 1 > mrg12_prodOrg.2012-06-1970.match_id

# # ---------- replace prodNote ----------
java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:objectProductionDateGroupList /tmp/mrg12_prodOrg.2012-06-1970.xml obj_prodDate.2012-06-19.xml /tmp/mrg13_prodDate.2012-06-1970.xml 0 1 > mrg13_prodDate.2012-06-1970.match_id

# # -------------------------------------------------
# # 5/10 add personDepicted, conetentInscription, annotate, comment, materialNote, nagpraDetermination, repatriationNote, taxonNote
# # note: nagpraDetermination, repatriationNote so far don't have any repeated case, so may be able to merge into main "object" run

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:contentPersons /tmp/mrg13_prodDate.2012-06-1970.xml obj_personDepicted.2012-06-19.xml /tmp/mrg14_psnDepict.2012-06-1970.xml 0 1 > mrg14_psnDepict.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:textualInscriptionGroupList /tmp/mrg14_psnDepict.2012-06-1970.xml obj_contentInscr.2012-06-19.xml /tmp/mrg15_contentInscr.2012-06-1970.xml 0 1 > mrg15_contentInscr.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_naturalhistory:annotationGroupList /tmp/mrg15_contentInscr.2012-06-1970.xml obj_annotate.2012-06-19.xml /tmp/mrg16_annotate.2012-06-1970.xml 0 1 > mrg16_annotate.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:comments /tmp/mrg16_annotate.2012-06-1970.xml obj_comment.2012-06-19.xml /tmp/mrg17_comment.2012-06-1970.xml 0 1 > mrg17_comment.2012-06-1970.match_id

# # ---------- replace nagpraDtm,
# # NOTE: switched material and material note.  We will want to combine these into one job
java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:materialGroupList /tmp/mrg17_comment.2012-06-1970.xml obj_material.2012-06-19.xml /tmp/mrg18_material.2012-06-1970.xml 0 1 > mrg18_material.2012-06-1970.match_id

# # NOTE: material note must be "append" to materialNote of the same GroupList (may want to switch around though) 
java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:materialGroupList /tmp/mrg18_material.2012-06-1970.xml obj_matrNote.2012-06-19.xml /tmp/mrg19_matrNote.2012-06-1970.xml 0 2 > mrg19_matrNote.2012-06-1970.match_id

# # ---------- replace repatrNote ----------
java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:contentPlaces /tmp/mrg19_matrNote.2012-06-1970.xml obj_placeDepicted.2012-06-19.xml /tmp/mrg20_placeDepicted.2012-06-1970.xml 0 1 > mrg20_placeDepicted.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_naturalhistory:taxonomicIdentGroupList /tmp/mrg20_placeDepicted.2012-06-1970.xml obj_taxonNote.2012-06-19.xml /tmp/mrg21_taxonNote.2012-06-1970.xml 0 1 > mrg21_taxonNote.2012-06-1970.match_id

# # ---------- new 6/14 ----------
java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:assocDateGroupList /tmp/mrg21_taxonNote.2012-06-1970.xml obj_assocDate.2012-06-21.xml /tmp/mrg22_assocDate.2012-06-1970.xml 0 1 > mrg22_assocDate.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:assocObjectGroupList /tmp/mrg22_assocDate.2012-06-1970.xml obj_assocObj.2012-06-19.xml /tmp/mrg23_assocObj.2012-06-1970.xml 0 1 > mrg23_assocObj.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:assocPeopleGroupList /tmp/mrg23_assocObj.2012-06-1970.xml obj_assocPeople.2012-06-19.xml /tmp/mrg24_assocPeople.2012-06-1970.xml 0 1 > mrg24_assocPeople.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:assocPlaceGroupList /tmp/mrg24_assocPeople.2012-06-1970.xml obj_assocPlace.2012-06-19.xml /tmp/mrg25_assocPlace.2012-06-1970.xml 0 1 > mrg25_assocPlace.2012-06-1970.match_id

# temporarily making this append until two assocPeopleGroupList jobs are merged
# 6/19/2012 YC --- merging key should be "collectionobjects_common:cntentPeoples" for "contentPeople" 
#                  (CH to change mapping in TMSobj_contentPeople Talend job)
java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:contentPeoples /tmp/mrg25_assocPlace.2012-06-1970.xml obj_contentPeople.2012-06-19.xml /tmp/mrg26_contentPeople.2012-06-1970.xml 0 2 > mrg26_contentPeople.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_common:measuredPartGroupList /tmp/mrg26_contentPeople.2012-06-1970.xml obj_dimension.2012-06-19.xml /tmp/mrg27_dimension.2012-06-1970.xml 0 1 > mrg27_dimension.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_pahma:pahmaFieldCollectionDateGroupList /tmp/mrg27_dimension.2012-06-1970.xml obj_fieldDate.2012-06-19.xml /tmp/mrg28_fieldDate.2012-06-1970.xml 0 1 > mrg28_fieldDate.2012-06-1970.match_id

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_pahma:pahmaFieldCollectionPlaceList /tmp/mrg28_fieldDate.2012-06-1970.xml obj_fieldPlace.2012-06-19.xml /tmp/mrg29_fieldPlace.2012-06-1970.xml 0 1 > mrg29_fieldPlace.2012-06-1970.match_id

# June 15 CRH adding pahmaObjectStatusList

java -Xms256M -Xmx1024M -classpath ../../bin xmlMerge.MergeGeneric5 collectionobjects_pahma:pahmaObjectID collectionobjects_pahma:pahmaObjectStatusList /tmp/mrg29_fieldPlace.2012-06-1970.xml obj_objStatus.2012-06-15.xml mrg30_objectStatus.2012-06-1970.xml 0 1 > mrg30_objectStatus.2012-06-1970.match_id

# --------------------------------------------------
# Trim the resulting (final) XML file (use TrimObj3)
# --------------------------------------------------
java -Xms256M -Xmx1024M -classpath ../../bin trimXml.TrimObj3 mrg30_objectStatus.2012-06-1970.xml mrg30_objectStatus.2012-06-1970.xml_trim.xml > objtrim_msg_2012-06-1970.msg

# -------------------------------------------------------
# Split the resulting (final) XML file before import 
# --- last argument is "prefix" of resulting split-files
# -------------------------------------------------------
java -Xms256M -Xmx1024M -classpath ../../bin splitXml.SplitImport 3500 mrg30_objectStatus.2012-06-1970.xml_trim.xml mrg30.2012-06-1970_trim > objmrg30.2012-06-1970_split.msg
