use strict;

while (<>) {
  # clean up stray urns :-(
  s/urn.cspace.botgarden.cspace.berkeley.edu.*?\|/|/g;
  my $keep = $_;
  chomp;
  my (@columns) = split '\|',$_,-1;
  $_ = @columns[26];
  # ad hoc tweaks..
  s/, +/,/g;s/Geographic range: +//;
  s/MEXICO/Mexico/;
  s/,? *(North America|South America|Central America|Europe|Asia)//;
  s/County,/,/;
  my @y=split ",",",,," . $_;
  if ($#y > 3) {
    splice @columns, 9, 3, @y[$#y - 2 .. $#y];
    print join('|',@columns). "\n";
  }
  else {
    print $keep;
  }
}
