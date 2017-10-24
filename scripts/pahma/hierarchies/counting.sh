./runpsql.sh $1 $2 tables.sql > counts/table.$1.counts &
./runpsql.sh $1 $2 groups.sql > counts/group.$1.counts &
wait
grep "|" table.$1.counts | grep -v "count" > counts/table.$1.txt
grep "|" group.$1.counts | grep -v "count" > counts/group.$1.txt
