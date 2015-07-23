#
perl -pe 's/template.cfg/barcodeprintProd.cfg/' Template.py > BarcodePrint.py 
perl -pe 's/template.cfg/keyinfoProd.cfg/' Template.py > KeyInfoRev.py 
perl -pe 's/template.cfg/packlistProd.cfg/' Template.py > PackingList.py 
perl -pe 's/template.cfg/sysinvProd.cfg/' Template.py > SystematicInventory.py 
perl -pe 's/template.cfg/searchProd.cfg/' Template.py > Search.py
#
perl -pe 's/template.cfg/sysinvDev.cfg/' Template.py > SystematicInventoryDev3.py 
perl -pe 's/template.cfg/uploadDev.cfg/' Template.py > BarcodeUpload.py 
#
sudo cp Bar*.py /var/www/cgi-bin/
sudo cp Systematic*.py /var/www/cgi-bin/
sudo cp Search*.py /var/www/cgi-bin/
sudo cp KeyInfo*.py /var/www/cgi-bin/
sudo cp PackingList*.py /var/www/cgi-bin/
