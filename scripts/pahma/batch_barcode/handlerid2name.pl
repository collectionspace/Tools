# takes a list of handler IDs, output a list of names
# using LocHandler.txt where there are matches; otherwise writes out the original input.

use strict;

open(INFILE, @ARGV[0]) || die 'could not open LocHandlers file: ' . @ARGV[0];
my @list = <INFILE>;
chomp @list;
close INFILE;
my %handlerhash = map { split /\t/ } @list;
while (my $namecode = <STDIN>) {
    chomp $namecode;
    if ($handlerhash{$namecode} ) {
        print "$handlerhash{$namecode}\n";
    }
    else {
        print "$namecode\n";
    }
}
