use strict;

my %count ;

open MEDIA,'media.csv';
my %media ;
while (<MEDIA>) {
  $count{'media'}++;
  chomp;
  my ($objectcsid, $objectnumber, $mediacsid, $description, $filename, $creatorrefname, $creator, $blobcsid, $copyrightstatement, $identificationnumber, $rightsholderrefname, $rightsholder, $contributor) = split '\|';
  #print "$blobcsid $objectcsid\n";
  $media{$objectcsid} .= $blobcsid . ',';
}

open METADATA,'metadata.csv';
while (<METADATA>) {
  $count{'metadata'}++;
  chomp;
  my ($objectid, @rest) = split '\|';
  # insert list of blobs as final column
  my $mediablobs = $media{$objectid};
  $mediablobs =~ s/,$//; # get rid of trailing comma
  print $_ . '|' . $mediablobs . "\n";
}

foreach my $s (sort keys %count) {
 warn $s . ": " . $count{$s} . "\n";
}
