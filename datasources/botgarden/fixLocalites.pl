use strict;

while (<>) {
  # clean up stray urns :-(
  s/urn.cspace.botgarden.cspace.berkeley.edu.*?\|/|/g;
  my $keep = $_;
  chomp;
  my (@columns) = split '\|',$_,-1;
  $_ = @columns[26];
  s/, +/,/g;s/Geographic range: +//;
  s/,? *(North America|South America|Europe|Asia)//;
  s/County,/,/;
  my @y=split ",",",,," . $_;
  if ($#y > 3) {
    #print  @y[$#y - 3 .. $#y];
    #print "\n";
    splice @columns, 9, 3, @y[$#y - 2 .. $#y];
    print join('|',@columns). "\n";
    #print $#columns . "\n";
  }
  else {
    print $keep;
  }
}
