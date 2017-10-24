#!/opt/ActivePerl-5.8/bin/perl -w

# this Perl script read in the handler code, and check against the master 
# "handler list", and write out the "displayName" from the master "handler list"
# wherever it matches; otherwise it writes out the original code.

use strict;

open(INFILE, "LocHandlers.txt");
my @list = <INFILE>;
chomp @list;
# print "# lines in handler-list file = " . @list . "\n";
my ($listline, $code, $dispname);
my %handlerhash;
foreach $listline (@list) {
    if ($listline =~ /^\s*$/) {
		next;
    }
    ($code, $dispname) = split /\t/, $listline;
    $handlerhash{$code} = $dispname;
}
close(INFILE);
# Debugging printout ------
# my ($k, $v, $listsize);
# print "list size = " . keys(%handlerhash) . "\n";
# while( ($k, $v) = each %handlerhash ) {
# 	print "key: $k, value: $v.\n";
# }
# for $k ( sort keys %handlerhash ) {
# 	print "$k: $handlerhash{$k}\n";
# }

my $line;
my $namecode;
my @dispname_trim;
my $n_dispname;
my $dispout;
my ($i, $nrecord, $total);
$i = 0;
while ($line = <>) {
    $namecode = $line;
    chomp $namecode;
	#$namecode =~ s/^ *[A-Za-z0-9] *$/$1/;
	#print "namecode = $namecode, name = $handlerhash{$namecode}";
    if ( exists $handlerhash{$namecode} ) {
		print "$handlerhash{$namecode}\n";
    }
	else {
		print "$line";
 	}
}


