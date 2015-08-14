use strict;

# restrict images of charmstones and funerary objects
# replace the blob csid with the csid of the 'restricted image' if the regex appears anywheren in the row
while (<>) {
  chomp;
  my (@columns) = split /\t/,$_,-1;
  #print "bef:\t" . $columns[10] . "\t" . $columns[37] . "\n";
  # use placeholder image if certain text appears anwhere in the record
  @columns[37] = '59a733dd-d641-4e1a-8552' if ($_ =~ /(charm.*stone|NAGPRA-associated Funerary Objects)/i && @columns[37]);
  # use placeholder image if context of use field contains the word burial
  @columns[37] = '59a733dd-d641-4e1a-8552' if (@columns[15] =~ /burial/i && @columns375]);
  #print "aft:\t" . $columns[10] . "\t" . $columns[37] . "\n";
  #print scalar @columns, "\n";
  print join("\t",@columns). "\n";
}

