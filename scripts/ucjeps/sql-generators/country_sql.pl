#This script generates the CSpace update SQL for changing country en masse
#Input file is a tab delimited table with the columns listed below, given on the command line

#Accumulate results in to_send directory and send to Chris periodically

    my $file = shift; #usage: perl country.pl datafile.txt

open(OUT,">country2sql.out") || die;;
open(ERR,">country_error.out") || die;;
	
open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless( $#columns==2){
		print ERR "$#columns bad field number $_\n";
	}



($aid,
$country)=@columns;

			print OUT <<EOP;
\\echo '$aid'
update localitygroup
set fieldLocCountry = '$country'
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
print "Success. see country2sql.out\n";