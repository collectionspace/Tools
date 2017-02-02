#This script generates the CSpace update SQL for correcting coordinates
#Input file is a tab delimited table with the columns listed below
#Georeferencer and georef_remarks are hardcoded into the printout

#Accumulate results and send to Chris periodically

    my $file = 'to_process/alpine_distance_kluge';

open(OUT,">georef2sql.out") || die;;
	
open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless( $#columns==6){
		print ERR "$#columns bad field number $_\n";
	}

($aid,
#$locality,
$latitude,
$longitude,
$georef_source,
$datum,
$error_radius,
$ER_units
)=@columns;


#####When not NULLing, all text fields must be enclosed by single quotes
#####Numeric fields, including decimallatitude and decimallongitude, must have the quotes left off

#####Hold lines removed from the print OUT
# fieldlocverbatim = '$locality',

			print OUT <<EOP;
\\echo '$aid'
update localitygroup
set vlatitude = '$latitude', 
 vlongitude = '$longitude', 
 decimallatitude = $latitude,
 decimallongitude = $longitude, 
 localitysource =  '$georef_source',
 georefsource = '$georef_source', 
 geodeticdatum = '$datum', 
 coorduncertainty = '$error_radius', 
 coorduncertaintyunit = '$ER_units',
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
print "Success. see georef2sql.out\n";