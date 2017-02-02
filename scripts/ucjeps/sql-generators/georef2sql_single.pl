#This script generates the CSpace update SQL for correcting coordinates
#Unlike georef2sql.pl, this is for updating many accessions with the same coordinates
#Input file is a list of accession IDs, one per line
#Values are hardcoded in the printout

#Accumulate results and send to Chris periodically

	my $file = shift; #usage: perl georef2sql_single.pl datafile.txt

open(OUT,">georef2sql_single.out") || die;;
	
open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless( $#columns==1){
		print ERR "$#columns bad field number $_\n";
	}

($aid)=@columns;

			print OUT <<EOP;
\\echo '$aid'
update localitygroup
set vlatitude = '37.92348', 
 vlongitude = '-122.67025', 
 decimallatitude = 37.92348,
 decimallongitude = -122.67025, 
 localitysource =  'BerkeleyMapper',
 georefsource = 'BerkeleyMapper', 
 geodeticdatum = 'WGS84', 
 coorduncertainty = 2500, 
 coorduncertaintyunit = 'm',
 georefremarks = 'batch update 10/30/2013',
 georefencedby = 'RLMoe'
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
print "Success. see georef2sql_single.out\n";