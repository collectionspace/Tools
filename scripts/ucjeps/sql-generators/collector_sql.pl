#This script generates the CSpace update SQL for updating field collector en masse
#Input file is a tab delimited table with the columns listed below
#note that the collector string and the CSpace shortref are needed

#NOTE: as far as I know, SQL escapes single quotes with two single quote characters
#I used this for the collector name and we will see how it works

#Accumulate results in to_send directory and send to Chris periodically

    my $file = shift; #usage: perl collector_sql.pl datafile.txt

open(OUT,">collector2sql.out") || die;;
open(ERR,">collector_error.out") || die;;
	
open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless( $#columns==2){
		print ERR "$#columns bad field number $_\n";
	}



($aid,
$collector_name,
$cspace_machine_name)=@columns;

foreach ($collector_name) {
	$collector = "urn:cspace:ucjeps.cspace.berkeley.edu:orgauthorities:name(organization):item:name($cspace_machine_name)''$collector_name''";
}

#print $collector;

			print OUT <<EOP;
\\echo '$aid'
update fieldcollectors
set fieldcollector = '$collector'
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
print "Success. see collector2sql.out\n";