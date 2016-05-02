use strict;

my %count ;
my $delim = "\t";

open MEDIA,$ARGV[0] || die "couldn't open media file $ARGV[0]";
my %blobs ;
my %seen;
my $restricted = '59a733dd-d641-4e1a-8552';
my $runtype = $ARGV[2]; # generate media for public or internal

my $fcpcol = 35;
my $contextofusecol = 13;
my $objectnamecol = 8;

while (<MEDIA>) {
  $count{'media'}++;
  chomp;
  my ($objectcsid,$objectnumber,$mediacsid,$description,$name,$creatorrefname,$creator,$blobcsid,$copyrightstatement,$identificationnumber,$rightsholderrefname,$rightsholder,$contributor,$approvedforweb,$pahmatmslegacydepartment,$objectstatus,$primarydisplay) = split /$delim/;
  #print "$blobcsid $objectcsid\n";
  # skip this blob if we've already seen it
  next if $seen{$blobcsid}++;
  my $imagetype = 'images';
  # mark catalog card images as such
  $imagetype = 'cards' if $description =~ /(catalog card|HSR Datasheet)/i;
  $imagetype = 'cards' if $description =~ /^Index/i ;
  my $ispublic = 'public';
  # we don't need to match a pattern here, it's a vocabulary. But just in case...
  $ispublic = 'notpublic' if ($pahmatmslegacydepartment =~ /Human Remains/i) ;
  $ispublic = 'notpublic' if ($pahmatmslegacydepartment =~ /NAGPRA-associated Funerary Objects/i) ;
  $ispublic = 'notpublic' if ($objectstatus =~ /culturally/i) ;
  # NB: the test 'burial' in context of use occurs below -- we only mask if the FCP is in North America
  $ispublic = 'notpublic' unless ($approvedforweb eq 't') ;
  #$ispublic = 'notapprovedforweb' unless ($approvedforweb eq 't') ;
  $ispublic = 'public' if ($imagetype eq 'cards') ;
  # warn $ispublic . $imagetype;
  $count{$imagetype}++;
  $count{$ispublic}++;
  # start by assuming no images for this object
  #$blobs{$objectcsid}{'hasimages'} = 'no';
  if ($imagetype eq 'cards') {
    $blobs{$objectcsid}{'cards'} .= $blobcsid   . ',' ;
  }
  else {
    $blobs{$objectcsid}{'hasimages'} = 'yes';
    # if this run is to generate the public datastore, use the restricted image if this blob is restricted.
    if ($runtype eq 'public') {
      $blobcsid = $restricted if ($ispublic ne 'public');
    }
    if ($primarydisplay eq 't') {
      $blobs{$objectcsid}{'primary'} = $blobcsid;
    }
    do {
      # add this blob to the list of blobs, unless we somehow already have it (no dups allowed!)
      $blobs{$objectcsid}{'images'} .= $blobcsid . ',' unless $blobs{$objectcsid}{'images'} =~ /$blobcsid/;
    }
  }
  $blobs{$objectcsid}{'type'} .= $imagetype  . ',' unless $blobs{$objectcsid}{'type'} =~ /$imagetype/;
  $blobs{$objectcsid}{'restrictions'} .= $ispublic   . ',' unless $blobs{$objectcsid}{'restrictions'} =~ /$ispublic/;
}

open METADATA,$ARGV[1] || die "couldn't open metadata file $ARGV[1]";
while (<METADATA>) {
  chomp;
  my ($id, $objectcsid, @rest) = split /$delim/;
  # handle header line
  if ($id eq 'id') {
    print $_ . $delim . join($delim,qw(blob_ss card_ss primaryimage_s imagetype_ss restrictions_ss hasimages_s)) . "\n";
    next;
  }
  $count{'metadata'}++;
  my $mediablobs;
  if ($blobs{$objectcsid}{'type'}) {
    if ($runtype eq 'public') {
      # if context of use field contains the word burial
      $blobs{$objectcsid}{'images'} = $restricted if (@rest[$contextofusecol] =~ /burial/i
      && @rest[$fcpcol] =~ /United States/i && $blobs{$objectcsid}{'images'});
      # if object name contains something like "charm stone"
      $blobs{$objectcsid}{'images'} = $restricted if (@rest[$objectnamecol] =~ /charm.*stone/i
      && @rest[$fcpcol] =~ /United States/i && $blobs{$objectcsid}{'images'});
      # belt-and-suspenders: restrict if charm stone or NAGPRA appear anywhere in USA records...
      $blobs{$objectcsid}{'images'} = $restricted if ($_ =~ /(charm.*stone|NAGPRA-associated Funerary Objects)/i
      && @rest[$fcpcol] =~ /United States/i && $blobs{$objectcsid}{'images'});
    }
    # insert list of blobs, etc. as final columns
    $blobs{$objectcsid}{'restrictions'} =~ s/,$//;
    $blobs{$objectcsid}{'type'} =~ s/,$//;
    $blobs{$objectcsid}{'type'} = join(',', sort(split(',', $blobs{$objectcsid}{'type'})));
    $blobs{$objectcsid}{'hasimages'} = 'no' unless $blobs{$objectcsid}{'hasimages'} eq 'yes';
    $count{'hasimages: ' . $blobs{$objectcsid}{'hasimages'}}++;
    for my $column (qw(images cards primary type restrictions hasimages)) {
      $mediablobs .= $delim . $blobs{$objectcsid}{$column};
    }
    $count{'object type: ' . $blobs{$objectcsid}{'type'}}++;
    $count{'object restrictions: ' . $blobs{$objectcsid}{'restrictions'}}++;
    $count{'matched: yes'}++;
  }
  else {
    $count{'matched: no'}++;
    $mediablobs = $delim x 6;
  }
  $mediablobs =~ s/,$delim/$delim/g; # get rid of trailing commas
  print $_ . $mediablobs . "\n";
}

foreach my $s (sort keys %count) {
 warn $s . ": " . $count{$s} . "\n";
}
