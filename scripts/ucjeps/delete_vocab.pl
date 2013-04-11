#!/usr/bin/perl

# UCJEPS-393: Delete an extraneous language vocabulary, and all of its items. This script may be reused to delete other vocabularies,
# with some changes to the global variables.

use strict;
use XML::XPath;
use XML::XPath::XMLParser;

#TODO: Pass some of these hardcoded values in as parameters to the script

$main::CURL_COMMAND = '/usr/bin/curl';
$main::CSPACE_HOSTNAME = 'cspace';
$main::CSPACE_PORT = 8180;
$main::CSPACE_USER = 'the username';
$main::CSPACE_PW = 'the password';
$main::VOCAB_CSID = 'the csid of the vocabulary to delete';

delete_vocab($main::VOCAB_CSID);

sub delete_vocab {
	my $vocab_csid = shift;
	
	delete_vocab_items($vocab_csid);
	
	my $delete_command = qq($main::CURL_COMMAND -X DELETE http://$main::CSPACE_HOSTNAME:$main::CSPACE_PORT/cspace-services/vocabularies/$vocab_csid -s -S -u "$main::CSPACE_USER:$main::CSPACE_PW");

	print $delete_command, "\n";
	my $delete_response = `$delete_command`;	
}

sub delete_vocab_items {
	my $vocab_csid = shift;
	my $get_command = qq($main::CURL_COMMAND http://$main::CSPACE_HOSTNAME:$main::CSPACE_PORT/cspace-services/vocabularies/$vocab_csid/items?pgSz=0 -s -S -u "$main::CSPACE_USER:$main::CSPACE_PW");

	print $get_command, "\n";
	my $item_payload = `$get_command`;

	#TODO: Check for error
	
	my $xml = XML::XPath->new(xml => $item_payload);
	my $nodeset = $xml->find('//list-item/uri');
	my @uris;
	
	foreach my $node ($nodeset->get_nodelist()) {
		push(@uris, $node->string_value());
	}
	
	foreach my $uri (@uris) {
		my $delete_command = qq($main::CURL_COMMAND -X DELETE http://$main::CSPACE_HOSTNAME:$main::CSPACE_PORT/cspace-services$uri -s -S -u "$main::CSPACE_USER:$main::CSPACE_PW");

		print $delete_command, "\n";
		my $delete_response = `$delete_command`;
		
		#TODO: Check for error
		
		print $delete_response, "\n";
	}
}