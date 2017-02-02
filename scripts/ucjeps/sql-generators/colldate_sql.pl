#This script generates the CSpace update SQL for changing collection date en masse
#Input file is a tab delimited table with the columns listed below, given on the command line

#NOTE: This is for single dates where year, month and day are known
#For date/month unknown, or date ranges, use colldate_range_sql.pl

#Accumulate results and send to Chris periodically

    my $file = shift;

open(OUT,">colldate2sql.out") || die;;
open(ERR,">colldate_error.out") || die;;
	
open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless( $#columns==4){
		print ERR "$#columns bad field number $_\n";
	}

($aid,
$csid,
$year,
$month,
$day)=@columns;

			print OUT <<EOP;
\\echo '$aid'
update structureddategroup
set dateearliestsingleyear = '$year',
 dateearliestsinglemonth = '$month',
 dateearliestsingleday = '$day',
EOP
print OUT " dateearliestscalarvalue = '$year-$month-$day"."T00:00:00Z',\n"; #so $day isn't interpreted as $dayT00
print OUT " datelatestscalarvalue = '$year-$month-$day"."T00:00:00Z'\n";
			print OUT <<EOP;
where id =
   (select sdg.id
   from collectionobjects_common co
   join hierarchy hfcdg on (co.id = hfcdg.parentid and hfcdg.name = 'collectionobjects_common:fieldCollectionDateGroup')
   join structureddategroup sdg on (sdg.id = hfcdg.id)
   where co.objectnumber = 
'$aid'
);

EOP
}
print "Success. see colldate2sql.out\n";