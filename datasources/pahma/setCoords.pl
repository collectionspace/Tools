use strict;

# create a yes/no value for objects with coordinates

my $coordcolumn = 0 + @ARGV[0];

while (<STDIN>) {
  chomp;
  my (@columns) = split /\t/,$_,-1;
  my $hascoords = (@columns[$coordcolumn] ne '') ? 'yes' : 'no';
  $hascoords = 'hascoords_s' if (@columns[$coordcolumn] =~ /_p/); # header
  print join("\t",@columns) . "\t" . $hascoords . "\n";
  #print "$hascoords = @columns[$coordcolumn]\n";
}

