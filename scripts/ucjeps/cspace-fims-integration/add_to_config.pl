use warnings;
use strict;

#This file should take in the following files:
#1) The current config file
#2) up-to-date taxon authority files
#3) The list of all names in the specimen batch, i.e. the input (The script will check whether it needs to be added or not)

my $authority_file;
my $config_file;
my $input_names;
$authority_file = "auth_file.txt" || die "authority file not found. Run prepare_file.sh\n";
$config_file = "ucjeps_fims.xml" || die "config file not found. Add config file ucjeps_fims.xml to directory\n";
$input_names = "input_names.txt" || die "input names file not found. Run prepare_file.sh\n";

open(LOG_FILE,">log.txt") || die "could not instantiate new log file\n";
open(FOR_CONFIG,">to_add_to_config.txt") || die "could not instantiate new config file\n";

my %REF;
my %AUTH;
my @authnames;
my @noauthnames;

open(IN, "$authority_file") || die "could not open authority file $authority_file\n";
while(<IN>){
	chomp;
	my ($csid,
	$author_name,
	$ref_name,
	$no_author_name,
	$major_group
	) = split (/\t/);

#is there a way to do it besides loading all author_names and noauthor_names into two different arrays?
#i.e. could the checking be done using the hash files?
#if so, the hash files would have to differentiate between author_names and noauthor_names
$author_name =~ s/\s+$//;

$no_author_name =~ s/\s+$//;

	push @authnames, "$author_name";
	if ("$no_author_name") { #not all entries will have no_author_names
		push @noauthnames, "$no_author_name";
	}

	$REF{$author_name} = $ref_name; #key the author_names to the refname
	$REF{$no_author_name} = $ref_name; #also key the noauthor name to the refname
	$AUTH{$no_author_name} = $author_name; #key authname to the noauthorname

}
close(IN);

####these tests could be done by doing a line count on the authority input files
####and making sure these print outs have an expected number of lines based on the input
#foreach(keys(%REF)){
#	print "$_: $REF{$_}\n";
#}
#foreach(keys(%AUTH)){
#	print "$_\t$AUTH{$_}\n";
#}
#foreach (@authnames){
#	print "$_\n";
#}
#foreach (@noauthnames){
#	print "$_\n";
#}

my @names_in_config;

open(IN, "$config_file") || die "could not open config file $config_file\n";
while(my $line = <IN>){
	chomp $line;
	#because we are matching complex strings, use Q\...E\
	#Q\ means "disable metacharacters until \E
	next unless ($line =~ /^\Q<field uri="urn:cspace:ucjeps.cspace.berkeley.edu:taxonomyauthority:name(taxon):item:name\E/); 
#	print "$line\n";
	if ($line =~ /.*\[CDATA\[(.*)\]\]/){ #if the line has a CDATA tag with content
#		print "$1\n";
		push @names_in_config, "$1";
	}
}
close(IN);

#foreach (@names_in_config){
#	print "$_\n";
#}
###The number of items in the @names_in_config array should equal the number of lines after the next unless


#finally, load the names from the current input and process line by line
open(IN, "$input_names") || die "could not open name list file $input_names\n";
while(my $input_name = <IN>){
	chomp $input_name;
    $input_name =~ s/\s+$//;
	#print "$input_name\n";
	if ($input_name =~ /^$/){
		print LOG_FILE "blank input names should be changed to \"Unknown\"\n";
	}
	
	elsif ( grep( /^\Q$input_name\E$/, @authnames ) ) { #if the input name exactly matches an item in the authnames array
		#print "is in the authority file: $input_name\n";
		#print nothing; pass the auth_name along to compare to the config file
	}

	elsif ( grep( /^\Q$input_name\E$/, @noauthnames ) ) { #if the input matches the noauth_name
		print LOG_FILE "noauthname match: please change input name $input_name to $AUTH{$input_name}\n";
		next;
	}

	elsif ($input_name =~ / / && grep( /^\Q$input_name\E/, @authnames ) ) { #elsif input matches the start of the string of an auth name
		my @partial_matches;
		@partial_matches = grep( /^\Q$input_name\E/, @authnames );
		print LOG_FILE "partial name match: suggested to change input name $input_name to one of following: ", join "; ",@partial_matches, "\n";
		next;
	}

	else {
		print LOG_FILE "name apparently not in the authority file, add to CSPACE: $input_name\n";
		next;
	}

	##now, once the name is confirmed as in CSpace and the input matches the auth name, check if the name is already in the config file
	if ( grep( /^\Q$input_name\E$/, @names_in_config ) ) { #if $input_name matches an item in the CONF array
		print LOG_FILE "name already in config file; no action required: $input_name\n";
		next;
	}

	else { #else the name is not in the config file and needs to be added
		#format ref name to the FIMS config format, i.e.:
		#ref name: urn:cspace:ucjeps.cspace.berkeley.edu:taxonomyauthority:name(taxon):item:name(23082)'Diplacus calycinus Eastw.'
		#FIMS format: <field uri="urn:cspace:ucjeps.cspace.berkeley.edu:taxonomyauthority:name(taxon):item:name(23082)"><![CDATA[Diplacus calycinus Eastw.]]></field>
		$REF{$input_name}=~s/^/<field uri="/;
		$REF{$input_name}=~s/\)'/)"><![CDATA[/;
		$REF{$input_name}=~s/'$/]]><\/field>/;
		#then print to config output so it can be pasted directly into FIMS config file
		print FOR_CONFIG "$REF{$input_name}\n";
	}

}

warn "add_to_config.pl complete.\n";
warn "See log.txt for suggested changes\n";
warn "and to_add_to_config.txt for lines to add to FIMS config file\n";

###Script should be re-run until the only messages received are "name in config: no action required" or "name must be added to CSpace"
###Once all names are added to CSpace then then iterate until the only message received is "no action required"
###Then continue with the process


###############These were some notes about the authority hash setup that might have already been addressed. Delete if so
#for each authname and noauthname, also need to key it to the refname. Put this in one REFNAME hash
#ALSO NEED TO KEY THE AUTHNAMES TO THE CORRESPONDING NOAUTHNAMES
###maybe key noauthnames to authnames then key authname to refname, then can indirectly key noauthnames to refnames if needed

