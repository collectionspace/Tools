#This script generates the CSpace update SQL for correcting coordinates
#Input file a file with a list of accession numbers, one per line.

#Accumulate results in to_send directory and send to Chris periodically

    my $file = shift; #usage: perl null_georefs.pl datafile.txt

open(OUT,">georef2sql.out") || die;;
	
open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless( $#columns==0){
		print ERR "$#columns bad field number $_\n";
	}

($aid)=@columns;


#####When not NULLing, all text fields must be enclosed by single quotes
#####Numeric fields, including decimallatitude and decimallongitude, must have the quotes left off

			print OUT <<EOP;
\\echo '$aid'
update localitygroup
set vlatitude = NULL, 
 vlongitude = NULL, 
 decimallatitude = NULL,
 decimallongitude = NULL, 
 localitysource =  NULL,
 georefsource = NULL, 
 geodeticdatum = NULL, 
 coorduncertainty = NULL, 
 coorduncertaintyunit = NULL,
 georefremarks = NULL,
 georefencedby = NULL
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
print "Success. see null_georefs.out\n";