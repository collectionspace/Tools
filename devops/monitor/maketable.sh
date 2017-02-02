echo > combined.txt
cat *.temp.txt | cut -f1 | sort -u | perl -pe "s/$/\t0/" > mask.txt
for t in bampfa botgarden cinefiles pahma ucjeps 
do
    join -a 2 -t $'\t' ${t}.temp.txt mask.txt | cut -f1,2 > tmp
    join -a 2 -t $'\t' combined.txt tmp > tmp2
    mv tmp2 combined.txt
done
rm tmp mask.txt

