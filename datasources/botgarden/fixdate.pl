use strict;

while (<>) {
  chomp;
  my (@columns) = split '\|',$_,-1;
  #my ($Y,$M,$D) = split '-',$columns[6];
  @columns[6] .= "T00:00:00Z" if @columns[6];
  #print scalar @columns, "\n";
  print join('|',@columns). "\n";
}

