#
sub toSec {
	my ($h,$m,$s) = split /:/,@_[0];
	return $s + 60 * ($m + (60 * $h));
	return ($result < 0) ? $result + 86400 : $result;
}
print "<html>\n<h1>Magic Bus Progress Report</h1>\n<table border=\"1\">";
print "\n<h2>" . scalar localtime() . "</h2>\n";

my @header = ('start date','start time','records loaded','total records','batch number','end date','end time','elapsed time','records/min');
print '<tr><th>' . join('<th>',@header) . '</tr>' . "\n";

my @vals;
my @oldvals;
my $line;
while (<>) {
	next unless /(Starting|records|Done)/;
	chomp;
	s/^== Done (.*?) PDT .*$/\t\1##/;
	s/^(\d+) .*?records 2012.*? /\1\t/;
	s/^==.*run (.*?) PDT.*/\1\t/;
	s/ *(\d\d:\d\d:\d\d)/\t\1\t/;
	s/ rel$//;
	$line .= $_;
	if ($line =~ s/\#\#//) {
		$_ = $line;
		$line =~ s/\t/ zzz /g;
		#print "\n" . $line . "\n";
		@vals = split /\t/;
        	$vals[2] = $vals[3] - $oldvals[3];
        	$elapsed = toSec($vals[6]) - toSec($vals[1]);
	        $vals[7] = ($elapsed < 0) ? $elapsed + 86400 : $elapsed ;
                $vals[7] = sprintf "%.1f", $vals[7] / 60.00;
        	#$vals[7] = join('/',($vals[7],toSec($vals[6]),toSec($vals[1])));
		print "</td></tr>\n<tr><td>" . join('</td><td>',@vals);
        	#print "</td></tr>\n";
        	@oldvals = @vals;
		$line = '';
	}
}
print "</table></html>\n"
