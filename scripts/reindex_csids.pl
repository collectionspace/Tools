#!/usr/bin/perl

# Reindex a list of csids read from a file.
# The file must contain one csid per line.
# The name of the file must start with the doctype, followed by a dash, e.g. CollectionObject-csids.txt.

use File::Spec;
use LWP;
use strict;

my $batch_host = 'REDACTED';
my $batch_csid = 'REDACTED';
my $batch_user = 'REDACTED';
my $batch_password = 'REDACTED';

my $batch_size = 100;
my $start_batch = 1;
my $stop_batch = 0;

select STDOUT;
$| = 1;

my $ua = LWP::UserAgent->new;
$ua->timeout(300);

my $filepath = $ARGV[0];
my ($volume, $directories, $filename) = File::Spec->splitpath($filepath);

$filename =~ /^(.*?)-/;

my $doc_type = $1;
die "Could not determine doctype from file name" unless $doc_type;

# print "doctype: ", $doc_type, "\n";

open(my $fh, '<:encoding(UTF-8)', $filepath) or die "Could not open file '$filepath' $!";

my $complete = 0;
my $batch_count = 0;
my $record_count = 0;

while (!$complete) {
	$batch_count = $batch_count + 1;
	
	my @batch_csids = ();

	for (my $i=0; $i<$batch_size; $i++) {
		my $row = <$fh>;
		last unless $row;
		
		chomp($row);

		push(@batch_csids, $row);
	}
	
	next if $batch_count < $start_batch;
	
	print "Reindexing batch $batch_count: " . scalar @batch_csids . " records starting with $batch_csids[0]\n";

	my $num_affected = invoke_batch(@batch_csids);
	
	$record_count = $record_count + $num_affected;
	
	if (scalar(@batch_csids) != $batch_size) {
		$complete = 1;
	}
	
	if ($stop_batch > 0 && ($batch_count >= $stop_batch)) {
		$complete = 1;
	}
}

close $fh;

print "Reindexed $record_count records\n";


sub invoke_batch {
	my @csids = @_;
	my $serialized_csids = serialize_csids(@csids);
	my $num_affected = 0;

	my $xml_payload = <<XMLPAYLOAD;
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<ns2:invocationContext xmlns:ns2="http://collectionspace.org/services/common/invocable">
	<mode>list</mode>
	<docType>$doc_type</docType>
	<listCSIDs>$serialized_csids
	</listCSIDs>
</ns2:invocationContext>
XMLPAYLOAD

	#print $xml_payload, "\n";
	
	my $batch_uri = "https://$batch_host/cspace-services/batch/$batch_csid";
	
	my $request = HTTP::Request->new(POST => $batch_uri);
	$request->content_type('application/xml');
	$request->content($xml_payload);
	$request->authorization_basic($batch_user, $batch_password);
	
	my $response = $ua->request($request);
	
	if ($response->is_success) {
		my $content = $response->decoded_content;
		$content =~ /<numAffected>(\d+)<\/numAffected>/;
		
		$num_affected = $1;
	}
	else {
		print $response->as_string, "\n";
	}
	
	return $num_affected;
}

sub serialize_csids {
	my @csids = @_;
	my $xml = '';
	
	foreach my $csid (@csids) {
		$xml = $xml . "\n\t\t<csid>$csid</csid>";
	}
	
	return $xml;
}
