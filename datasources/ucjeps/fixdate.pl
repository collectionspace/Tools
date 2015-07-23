use strict;

while (<>) {
  chomp;
  my (@columns) = split "\t",$_,-1;
  #my ($Y,$M,$D) = split '-',$columns[7];
  @columns[11] .= "T00:00:00Z" if @columns[11];
  @columns[12] .= "T00:00:00Z" if @columns[12];
  @columns[33] =~ s/ /T/;
  @columns[33] .= 'Z';
  #print scalar @columns, "\n";
  print join("\t",@columns). "\n";
}

