cd /usr/local/share/django/botgarden_project/
cd gbif
cp /home/developers/botgarden/4solr.botgarden.metadata.csv.gz .
cd /home/developers/botgarden
gunzip 4solr.botgarden.metadata.csv.gz 
mv 4solr.botgarden.metadata.csv botgarden.csv
cut -f33 botgarden.csv > scinames.csv
less scinames.csv 
head -1 botgarden.csv 
cut -f4 botgarden.csv > scinames.csv
less scinames.csv 
vi scinames.csv 
python parseAndInsertGBIFparts.py 4solr.botgarden.metadata.csv output.csv names.pickle 3
# python parseNamesGBIF4UCBG.py scinames.csv parsednames.csv names.pickle
# nohup python /usr/local/share/django/botgarden_project/gbif/parseNamesGBIF4UCBG.py scinames.csv parsednames.csv names.pickle &
#       python /usr/local/share/django/botgarden_project/gbif/parseNamesGBIF4UCBG.py scinames.csv parsednames.csv names.pickle
cut -f15 parsednames.csv | less
cut -f12 parsednames.csv | less
cut -f12 parsednames.csv | sort | uniq -c
