#
sub toSec {
	my ($h,$m,$s) = split /:/,@_[0];
	return $s + 60 * ($m + (60 * $h));
	return ($result < 0) ? $result + 86400 : $result;
}
print "<html>\n<a name=\"top\"/>\n<h1>Magic Bus Progress Report</h1>\n<table border=\"1\">";
print "\n<h2>last updated: " . scalar localtime() . "</h2>\n";

my @logs = </home/developers/import/*/magicbus.*.log>; 
# override log list if user provided a file name
#my @logs = @ARGV[0] if (1 == scalar @ARGV);
my $reports;

print "\n<h2>Last observed update/import activity</h2>\n";
print "<pre>\n";
print `ps aux | perl -ne 'next if /monitorBus/;next unless /(jblowe|choffman|yuteh)/;next unless /(curl|bin|magic)/;s/\-u +/-u /;print if /bin|magic|curl/'`;
print "\n<\pre>\n";

open RAWDATA,">rawdata.csv";
print "\n<table border=\"1\">\n";
my @header = ('log','records','run time (m)','batches','failed batches','successful batches','first date','last date','running');
print '<tr><th>' . join('<th>',@header) . '</tr>' . "\n";
foreach $log (@logs) {
	#my ($logname,$run,$totalrecords,$elapsedtime,$totalruns,$failedruns,$succesfulruns,$report) = processLog($log);
	my (@results) = processLog($log);
	my $link = "<a href=\"#$results[0]\">$results[1]</a>";
	print "<tr><th>$link</th><td>", join('</td><td>',@results[2..9]), "</td></tr>\n";
	$reports .= $results[10];
}
print "</table>\n";
print "<hr><h2>Individual Runs</h2><hr>";
print $reports;
print "</html>\n";

sub processLog {
	my ($log) = shift;
	open LOG,$log;
my @header = ('start date','start time','records loaded','total records','batch number','end date','end time','elapsed time','remarks');

my ($runname) = $log =~ /magicbus.(.*).log/;
my @vals;
my @oldvals;
my $line;
my $totalrecords = 0;
my $elapsedtime = 0;
my $totalruns = 0;
my $failedruns = 0;
my %batches;
my $report =   "<a name=\"$log\">\n<a href=\"#top\">Top</a>\n<h2>Magic Bus Run: $runname</h2>\n<h4>log: $log</h4>\n";
$report .=  "\n<table border=\"1\"><tr><th>" . join('<th>',@header) . '</tr>' . "\n";
while (<LOG>) {
	if (/Reset values/) {
		/Reset values: (\d+) (\d+)/ && (($increment,$resetcounter) = ($1,$2));
		$oldvals[3] = $resetcounter;
		$totalrecords += $increment;
	}
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
        	@oldvals = @vals;
		$line = '';
		if ($vals[2] > 30000) {
                        $vals[2] = '5000';
			$vals[8] = 'unverified';
		}
		$totalrecords += $vals[2];
		$elapsedtime += $vals[7];
		$totalruns += 1;
		if ($vals[2] eq 0) { 
			$failedruns += 1;
			 
		}
		$batches[$val[4]]++;
		$report .=  "</td></tr>\n<tr><td>" . join('</td><td>',@vals);
		print RAWDATA "$log\t$runname\t" . join("\t",@vals) . "\n";
	}
}
$report .= "</table>\n";
my $numbatches = scalar @{ keys %batches };
return ($log,$runname,$totalrecords,sprintf("%.1f",$elapsedtime),$totalruns,$failedruns,($totalruns-$failedruns),
	'','','',$report);
}
