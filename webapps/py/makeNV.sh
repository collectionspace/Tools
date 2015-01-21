cp cswaDB.py cswaDBNV.py
cp cswaUtils.py cswaUtilsNV.py
cp cswaMain.py cswaMainNV.py
cp cswaObjDetails.py cswaObjDetailsNV.py
cp cswaDBobjdetails.py cswaDBobjdetailsNV.py
cp cswaConceptutils.py cswaConceptutilsNV.py
cp cswaConstants.py cswaConstantsNV.py
cp cswaCollectionUtils.py cswaCollectionUtilsNV.py
cp cswaGetPlaces.py cswaGetPlacesNV.py
cp cswaGetAuthorityTree.py cswaGetAuthorityTreeNV.py
cp cswaCollectionDB.py cswaCollectionDBNV.py
perl -i -pe "s/import cswa(.*?)\b/import cswa\1NV/;s/from cswa(.*?) import/from cswa\1NV import/" cswa*NV.py
scp cswa*NV.py dev.cspace.berkeley.edu:/var/www/cgi-bin/
