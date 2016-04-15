#
# fragile script to regenerate the cache (pickle) of GBIF parsed name parts
# 
# invoke as: ./generate.sh
#
# if you want to regenerate the cache from scratch, erase names.pickle
#
cd ~/solrdatasources/botgarden/gbif
cp ../4solr.botgarden.public.csv.gz .
gunzip 4solr.botgarden.public.csv.gz 
mv 4solr.botgarden.public.csv botgarden.csv
# just to be clear: we are reparsing the determination field from the previous
# night's extract
cut -f17 botgarden.csv > scinames.csv
# this version of the script is a bit rude: it hits GBIF sequentially, but without pauses
python parseNamesGBIF4UCBG.py scinames.csv parsednames.csv names.pickle
# nohup python /usr/local/share/django/botgarden_project/gbif/parseNamesGBIF4UCBG.py scinames.csv parsednames.csv names.pickle &
# python /usr/local/share/django/botgarden_project/gbif/parseNamesGBIF4UCBG.py scinames.csv parsednames.csv names.pickle
# cut -f15 parsednames.csv | less
# cut -f12 parsednames.csv | less
# cut -f12 parsednames.csv | sort | uniq -c
rm botgarden.csv
