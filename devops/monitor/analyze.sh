echo "<h2>Django Webapp Usage Summary</h2>" > summary.html
echo "<h4>`date`</h4>" >> summary.html
echo '
    <link rel="stylesheet" type="text/css" href="css/reset.css">
    <link rel="stylesheet" type="text/css" href="css/base.css">' >> summary.html
for t in bampfa botgarden cinefiles pahma ucjeps 
do
    echo "processing ${t} ..."
    ./genlogs.sh ${t}
    ./topblobs.sh ${t}
    echo "<p/>" >> summary.html
    echo "<a target=\"blobs\" href=\"${t}.blobs.html\">Top 100 Blobs for ${t}</a>" >> summary.html
done
mv summary.html /var/www/static
