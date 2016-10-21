#This script generates the CSpace update SQL adding datum
#Input file is a list of accession numbers
#Datum is hard-coded into OUT

#Accumulate results and send to Chris periodically

    my $file = shift; #usage: perl change_datum.pl datafile.txt

open(OUT,">datum_sql.out") || die;;
	
open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless( $#columns==0){
		print ERR "$#columns bad field number $_\n";
	}

($aid)=@columns;

			print OUT <<EOP;
\\echo '$aid'
update localitygroup
set geodeticdatum = 'NAD27', 
where id in
 (select lg.id FROM
  localitygroup lg, hierarchy h, collectionobjects_common cc
  where lg.id=h.id and h.parentid=cc.id
  and h.pos=0 and h.name='collectionobjects_naturalhistory:localityGroupList'
  and cc.objectnumber in (
'$aid'
 )
);

EOP
}
print "Success. see datum_sql.out\n";