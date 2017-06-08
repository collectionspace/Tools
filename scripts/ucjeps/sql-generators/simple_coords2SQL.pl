#This script generates the CSpace update SQL for correcting coordinates
#Input file is a tab delimited table with the columns listed below
#Georeferencer and georef_remarks are hardcoded into the printout

#Accumulate results and send to Chris periodically

    my $file = shift; #usage: perl simple_coords2SQL.pl datafile.txt

open(OUT,">georef2sql.out") || die;;
	
open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless( $#columns==3){
		print ERR "$#columns bad field number $_\n";
	}

($aid,
$latitude,
$longitude)=@columns;

			print OUT <<EOP;
\\echo '$aid'
update localitygroup
set vlatitude = '$latitude', 
 vlongitude = '$longitude', 
 decimallatitude = $latitude,
 decimallongitude = $longitude,  
 georefremarks = 'batch update to add minus sign 2014-07'
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
print "Success. see georef2sql.out\n";