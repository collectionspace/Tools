# assuming that the log extract has been made in /tmp, this script
# will aggregate them...
for t in bampfa botgarden cinefiles pahma ucjeps webapps
do
    echo "processing ${t} ..."
    sort -u /tmp/${t}.access.log > tmp1.log
    sort -m -u tmp1.log ${t}.access.log > tmp2.log
    mv tmp2.log ${t}.access.log
    rm tmp1.log
done
