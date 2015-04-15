use strict;

# replace the blob csid with the csid of the 'restricted image' if the letters c-h-a-r-m appear in the objectname
while (<>) {
  chomp;
  my (@columns) = split /\t/,$_,-1;
  #print "bef:\t" . $columns[10] . "\t" . $columns[37] . "\n";
  @columns[37] = '59a733dd-d641-4e1a-8552' if ((@columns[10] =~ /charm/i) && @columns[37]);
  #print "aft:\t" . $columns[10] . "\t" . $columns[37] . "\n";
  #print scalar @columns, "\n";
  print join("\t",@columns). "\n";
}

