#!/opt/ActivePerl-5.8/bin/perl -w

# this Perl script split fields of lines on '|' and re-join them by tab
# (script used by "talendinput.sh" to create tab-delimited file containing
# just the handlers/objects/locations/crates in the barcode files)

use strict;

my @in = <>;
chomp @in;

my $line;
my @refname;
my @refname_trim;
my $n_refname;
my $refout;
my ($i, $nrecord, $total);
$i = 0;
foreach $line (@in) {
    $i++;
    if ($i <= 2) {	# skip 2 header lines
		next;
    }
	@refname = split /\|/, $line;
    $nrecord++;
	@refname_trim = ();
	@refname_trim = alltrim(@refname);
	$refout="";
	$refout = join("\t", @refname_trim);
	print "$refout\n";
}


########################################################################

sub alltrim {           # trim leading or ending space characters
    my $one;
    my @list;
    foreach (@_) {
        $_ =~ /^\s*(\S.*\S)\s*$/;
        $one = $1;
        push(@list, $one);
    }
    return @list;
}

