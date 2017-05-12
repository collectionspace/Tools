use strict;

# modify dates to conform ISO-6301, which is all Solr accepts.
while (<>) {
  chomp;
  my (@columns) = split "\t",$_,-1;
  #my ($Y,$M,$D) = split '-',$columns[7];
  # fix earlycollectiondate_dt and latecollectiondate_dt
  @columns[11] .= "T00:00:00Z" if @columns[11];
  @columns[12] .= "T00:00:00Z" if @columns[12];
  # fix updatedat_dt
  @columns[33] =~ s/ /T/;
  @columns[33] .= 'Z';
  # fix createdat_dt
  @columns[62] =~ s/ /T/;
  @columns[62] .= 'Z';

  #print scalar @columns, "\n";
  print join("\t",@columns). "\n";
}

