echo "<html><h2>Django Webapp Usage Summary</h2>" > summary.html
echo "<h4>`date`</h4>" >> summary.html
echo '<head>
    <link rel="stylesheet" type="text/css" href="css/reset.css">
    <link rel="stylesheet" type="text/css" href="css/base.css">
    <style>
    td {text-align: right;}
    </style>
</head>
<table>' >> summary.html
for t in bampfa botgarden cinefiles pahma ucjeps 
do
    echo "processing ${t} ..."
    ./genlogs.sh ${t}
    ./topblobs.sh ${t}
    #echo "<a target=\"blobs\" href=\"${t}.blobs.html\">Top 100 Blobs for ${t}</a>" >> summary.html
done
./maketable.sh
perl -pe 'print "<tr><th>";s/\t/<td>/g;' combined.txt >> summary.html
head -1 combined.txt |perl -pe 'print "<tr><th>";s/(\w+)/<a target="blobs" href="\1.blobs.html">top images<\/a>/g;s/\t/<td>/g;' >> summary.html
echo '</table><html>' >> summary.html
mv summary.html /var/www/static
