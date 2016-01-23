use strict;

my %count ;
my $delim = "\t";

open MEDIA,$ARGV[0] || die "couldn't open media file $ARGV[0]";
my %blobs ;
my %seen;
my $restricted = '59a733dd-d641-4e1a-8552';
my $runtype = $ARGV[2]; # generate media for public or internal

while (<MEDIA>) {
  $count{'media'}++;
  chomp;
  my ($objectcsid,$objectnumber,$mediacsid,$description,$name,$creatorrefname,$creator,$blobcsid,$copyrightstatement,$identificationnumber,$rightsholderrefname,$rightsholder,$contributor,$approvedforweb,$pahmatmslegacydepartment,$objectstatus,$primarydisplay) = split /$delim/;
  #print "$blobcsid $objectcsid\n";
  # skip this blob if we've already seen it
  #next if $seen{$mediacsid}++;
  my $imagetype = 'image';
  $imagetype = 'card' if $description =~ /(catalog card|HSR Datasheet)/i;
  $imagetype = 'card' if $description =~ /^Index/i ;
  my $ispublic = 'public';
  # we don't need to match a pattern here, but this is a free text field...
  $ispublic = 'notpublic' if ($pahmatmslegacydepartment =~ /Human Remains/i) ;
  $ispublic = 'notpublic' if ($objectstatus =~ /culturally/i) ;
  # warn $ispublic . $imagetype;
  $count{$imagetype}++;
  $count{$ispublic}++;
  if ($imagetype eq 'card') {
    $blobs{$objectcsid}{'card'} .= $blobcsid   . ',' ;
  }
  else {
    # if this run is to generate the public datastore, use the restricted image if this blob is restricted.
    if ($runtype eq 'public') {
      $blobcsid = $ispublic eq 'public' ? $blobcsid   . ',' : $restricted . ',';
    }
    if ($primarydisplay eq 't') {
      $blobs{$objectcsid}{'primary'} = $blobcsid;
    }
    else {
      $blobs{$objectcsid}{'image'} .= $blobcsid;
    }
  }
  $blobs{$objectcsid}{'type'} .= $imagetype  . ',' unless $blobs{$objectcsid}{'type'} =~ /$imagetype/;
  $blobs{$objectcsid}{'type'} .= $ispublic   . ',' unless $blobs{$objectcsid}{'type'} =~ /$ispublic/;
}

open METADATA,$ARGV[1] || die "couldn't open metadata file $ARGV[1]";
while (<METADATA>) {
  chomp;
  my ($id, $objectid, @rest) = split /$delim/;
  # handle header line
  if ($id eq 'id') {
    print $_ . $delim . join($delim,qw(blob_ss card_ss primaryimage_s imagetype_ss)) . "\n";
    next;
  }
  $count{'metadata'}++;
  my $mediablobs;
  my $foundobject = $blobs{$objectid};
  if ($foundobject) {
  # insert list of blobs, etc. as final columns
    $blobs{$objectid}{'type'} =~ s/,$//;
    $blobs{$objectid}{'type'} = join(',', sort(split(',', $blobs{$objectid}{'type'})));
    for my $column (qw(image card primary type)) {
      $mediablobs .= $delim . $blobs{$objectid}{$column};
    }
    $count{'object: ' . $blobs{$objectid}{'type'}}++;
    $count{'matched'}++;
  }
  else {
    $count{'unmatched'}++;
    $mediablobs = $delim x 4;
  }
  $mediablobs =~ s/,$delim/$delim/g; # get rid of trailing commas
  print $_ . $mediablobs . "\n";
}

foreach my $s (sort keys %count) {
 warn $s . ": " . $count{$s} . "\n";
}
