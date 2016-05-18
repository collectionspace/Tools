#This script generates the CSpace update SQL for changing collection date en masse
#Input file is a tab delimited table with the columns listed below, given on the command line

#NOTE: This is for date ranges, including when day or month are unknown
#For single dates, use colldate_sql.pl

#Accumulate results in and send to Chris periodically

    my $file = shift; #usage: perl colldate_range_sql.pl datafile.txt

open(OUT,">colldaterange2sql.out") || die;;
open(ERR,">colldaterange_error.out") || die;;
	
open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless( $#columns==6){
		print ERR "$#columns bad field number $_\n";
	}

($aid,
$e_year,
$e_month,
$e_day,
$l_year,
$l_month,
$l_day)=@columns;

print OUT <<EOP;
\\echo '$aid'
update structureddategroup
set dateearliestsingleyear = '$e_year',
 dateearliestsinglemonth = '$e_month',
 dateearliestsingleday = '$e_day',
EOP
print OUT " dateearliestscalarvalue = '$e_year-$e_month-$e_day"."T00:00:00Z',\n";
print OUT <<EOP;
 datelatestyear = '$l_year',
 datelatestmonth = '$l_month',
 datelatestday = '$l_day',
EOP
print OUT " datelatestscalarvalue = '$l_year-$l_month-$l_day"."T00:00:00Z'\n";
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
print "Success. see colldaterange2sql.out\n";