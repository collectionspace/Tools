#!/usr/bin/perl

use DBI;
use LWP;
use strict;

my $db_host = 'REDACTED';
my $db_name = 'REDACTED';
my $db_user = 'REDACTED';
my $db_password = 'REDACTED';

my $batch_host = 'REDACTED';
my $batch_csid = 'REDACTED';
my $batch_user = 'REDACTED';
my $batch_password = 'REDACTED';

my $doc_type = "Relation";
my $tenant_id = "15";
my $batch_size = 1000;
my $start_batch = 1;
my $stop_batch = 0;

select STDOUT;
$| = 1;

my $ua = LWP::UserAgent->new;
$ua->timeout(300);

my $dbh = DBI->connect("dbi:Pg:dbname=$db_name;host=$db_host", $db_user, $db_password) or die $DBI::errstr;
my $sql = <<SQL;
	SELECT h.name AS csid
	FROM hierarchy h
	LEFT JOIN collectionspace_core cc ON h.id = cc.id
	LEFT JOIN misc m ON h.id = m.id
	WHERE ((h.primarytype LIKE ('$doc_type%'))
		AND (cc.tenantid = '$tenant_id')
		AND (m.lifecyclestate <> 'deleted')
		AND (h.isversion IS NULL))
	ORDER BY cc.createdat, h.name
SQL

my $sth = $dbh->prepare($sql);

$sth->execute();


my $complete = 0;
my $batch_count = 0;
my $record_count = 0;

while (!$complete) {
	$batch_count = $batch_count + 1;
	
	my @batch_csids = ();

	for (my $i=0; $i<$batch_size; $i++) {
		my @row = $sth->fetchrow_array;
		last unless @row;
		
		push(@batch_csids, $row[0]);
	}
	
	next if $batch_count < $start_batch;
	
	print "Reindexing batch $batch_count: " . scalar @batch_csids . " records starting with $batch_csids[0]\n";

	my $num_affected = invoke_batch(@batch_csids);

	$record_count = $record_count + $num_affected;
	
	if ($num_affected != $batch_size) {
		$complete = 1;
	}
	
	if ($batch_count >= $stop_batch) {
		$complete = 1;
	}
}

$sth->finish();

$dbh->disconnect or warn $dbh->errstr;

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
	
	my $batch_uri = "http://$batch_host:8180/cspace-services/batch/$batch_csid";
	
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
