# command line arguments (yes, there are a lot!)
my ($cspaceurl,$user,$password,$authority,$service,$template,$infile) = @ARGV;

print ">>>starting upload " .`date` ."\n";
print "cspaceurl\t$cspaceurl\n";
print "user\t$user\n";
print "password\t$password\n";
print "authority\t$authority\n";
print "service\t$service\n";
print "template\t$template\n";
print "infile\t$infile\n";

my $tempfile = rand(0) . ".xml";

# function to encode the 5 XML entities
# NB: this sub avoids double encoding & when it is used in an existing entity...
my @entities_bare=qw/&(?!\w{2,4};) " ' < >/;
my @entities_encoded=qw/&amp; &quot; &apos; &lt; &gt;/;

sub encode_entities {
	my $string=shift;
	for(my $n=0;$n<scalar @entities_bare;++$n){
		if(not $string=~s/$entities_bare[$n]/$entities_encoded[$n]/g){
		}
	}
	return $string;
}

my $command;

# if the csid of an authority is *not* provided (e.g. for loading an authority) then skip it...
if ($authority eq "") {

  $command ="curl -i -S --stderr - --basic -u $user:$password -X POST -H " .'"Content-Type:application/xml"' .
    " $cspaceurl/cspace-services/$service -T $tempfile";

}
# otherwise provide it in the POST request...
else {

  $command ="curl -i -S --stderr - --basic -u $user:$password -X POST -H " .'"Content-Type:application/xml"' .
    " $cspaceurl/cspace-services/$service/" . $authority . "/items -T $tempfile";
}

print "\ncurl command used:\n";
print $command . "\n";

# OK, here we go... open the files, set up a few things, then start POSTing...

open TEMPLATE,$template || die "count not open template file $template";
open DATAFILE,$infile   || die "count not open data file $infile";

# 1st line of the data file had better be a header saying how to match the columns to
# the XML elements in the template.

my $header = <DATAFILE> ;
chomp($header);
my @fields = split(/\t/,$header);
my @template = <TEMPLATE>;
my $templateString = join '',@template;

$count = 0;
while (<DATAFILE>) {
  chomp;
  my $tmpTemplate = $templateString;
  my @cols = split /\t/;
  for (my $i = 0 ; $i < scalar @fields ; $i++) {
    #print "$i $fields[$i]\n";
    my $str = encode_entities($cols[$i]);
    #$str =~ s/([\]\[\)\(])/\\$1/g;
    $tmpTemplate =~ s/#$fields[$i]#/$str/g;
  }
  $tmpTemplate =~ s/#authority#/$authority/g;
  if ($tmpTemplate =~ /#\w+#/) {
    die "$tmpTemplate\n\nunsubstituted value in template, aborting!\n";
  }
  open TEMP,">$tempfile" || die "count not open temporary file $tempfile for write.";
  print TEMP $tmpTemplate;
  $result = system($command);
  # should make sure the POST succeeded... add this code someday
  $count++;
}

print "\n$count POSTs made\n\n";
print ">>>end of upload " . `date` . "\n";
system("rm $tempfile");
