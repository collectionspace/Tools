#
use strict;

my $set  = @ARGV[0];
my $dir  = @ARGV[1];
my $type = @ARGV[2];
my $date = @ARGV[3];
my $script = @ARGV[4];
my %batches;
open RAWDATA,"/home/jblowe/rawdata.csv" || die "couldn't open rawdata.csv!";
print "# set: $set, date=$date timestamp: ". scalar localtime() . "\n";
while (<RAWDATA>) {
        chomp;
	my ($log,$runname,$sd,$st,$numloaded,$totalrecs,$batch,$ed,$et,$elapsed) = split /\t/;
        next unless ($runname eq $type);
	$batches{$batch + 0} += $numloaded;
	#print "$runname ... $batch .. $numloaded\n";
}
my ($r1,$r2);
foreach my $batch (sort { $a <=> $b } keys %batches) {
	#print $batch . ": " . $batches{$batch} . "\n";
	if ($batches{$batch} != 5000) {
		$r1 .= "cp ziptempdir/${set}.$date${batch}.xml retry\n";
                $r2 .=  "./$script $date $batch $dir $set $date $type\n";
                #print $batch . ": " . $batches{$batch} . "\n";
		#printf $cmd."\n",$batch,$batches{$batch};
	}
}
print "\n#input files to copy:\n";
print $r1;
print "\n#batches to rerun:\n";
print $r2;
