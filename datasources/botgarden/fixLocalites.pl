use strict;

open COUNTRIES,'<country.csv';
my %countries;
grep { chomp; my @temp = split /\t/; $countries{$temp[1]} = $temp[0]; } <COUNTRIES>;
warn "countries: " . (scalar keys %countries) . "\n";

open COUNTIES,'<county.csv';
my %counties;
grep { chomp; my @temp = split /\t/; $counties{$temp[1]} = $temp[0]; } <COUNTIES>;
warn "counties: " . (scalar keys %counties) . "\n";

open STATES,'<state.csv';
my %states;
grep { chomp; my @temp = split /\t/; $states{$temp[1]} = $temp[0]; } <STATES>;
warn "states: " . (scalar keys %states) . "\n";

#foreach my $x ( keys %countries) {
#print "$x\n";
#}

sub extractGeographicRange {
  my ($range) = @_;
  $range =~ s/Geographic range: *//;
  my (@county,@state,@country);
  foreach my $t (split ',', $range) {
    #warn 'xxx' . $t . "xxx\n";
    #warn 'zzz' . $countries{$t} . "\n";
    push @country, $t if $countries{$t};
    push @state, $t if $states{$t};
    $t =~ s/ Co\.$//;
    push @county, $t if $counties{$t};
  }
  return (
    join('|', @county),
    join('|', @state),
    join('|', @country),
  );
}

my $linecounter = 0;
while (<>) {
  $linecounter++;
  # clean up stray urns :-(
  s/urn.cspace.botgarden.cspace.berkeley.edu.*?\t/\t/g;
  my $keep = $_;
  chomp;
  my (@columns) = split "\t",$_,-1;
  $_ = @columns[26];
  s/ *, */,/g; # get rid of all spaces around commas
  my @triple;
  # ad hoc tweaks..
  if (/Geographic range:/) {
    @triple = extractGeographicRange($_);
    #warn 'original: ' . $_ . ' triple ' . join('::',@triple) . ", " . $#triple . "\n";
  }
  else {
    s/MEXICO/Mexico/;
    s/,? *(North America|South America|Central America|Europe|Asia|Africa)//;
    s/ *County,/,/;
    @triple = split ",",",,," . $_;
  }
  if ($#triple >= 2 && $linecounter != 1) {
    splice @columns, 9, 3, @triple[$#triple - 2 .. $#triple];
    print join("\t",@columns). "\n";
  }
  else {
    print $keep;
  }
}
