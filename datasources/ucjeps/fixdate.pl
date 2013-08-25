use strict;

while (<>) {
  chomp;
  my (@columns) = split '\|',$_,-1;
  #my ($Y,$M,$D) = split '-',$columns[7];
  @columns[7] .= "T00:00:00Z" if @columns[7];
  #print scalar @columns, "\n";
  print join('|',@columns). "\n";
}

