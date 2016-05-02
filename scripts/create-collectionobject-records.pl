#!/usr/bin/perl

# Quickly adds a specified number of minimal
# CollectionObject (aka Cataloging) records
# to a CollectionSpace system, for testing purposes.

#####################################

use File::Basename;
use File::Temp qw/tempfile tempdir/;
use Getopt::Long;

use strict;

my $verbose = 0;

my $script_name = basename($0);

my $default_num_to_create = 20;
my $num_to_create = $default_num_to_create;
my $max_to_create = 1000;
my $default_start_value = 1;
my $start_value = $default_start_value;
my $place_refname = "";
my $help = 0;

GetOptions(
    'help' => \$help,
    'num_to_create=i' => \$num_to_create,
    'place_refname' => \$place_refname,
    'start_value=i' => \$start_value) or die;

if ($help) {
    &print_usage();
    exit(0);
}

&validateIntegerOptionValue($num_to_create);
$num_to_create = min($num_to_create, $max_to_create);
&validateIntegerOptionValue($start_value);

my $curl_executable = `which curl`;
chomp($curl_executable); # remove newline
die "Could not find 'curl' executable"
  unless (-x $curl_executable);

my $temp_directory = tempdir( CLEANUP => 1 );

my ($TEMP_FILEHANDLE, $temp_filename) = tempfile();
print "temp filename=$temp_filename\n" if $verbose;

print $TEMP_FILEHANDLE &getHeader();

my $i;
for ($i=$start_value; $i < ($num_to_create + $start_value); $i++) {
    
    my $record = <<RECORD;
    <import service="CollectionObjects" type="CollectionObject">
      <schema xmlns:collectionobjects_common="http://collectionspace.org/services/collectionobject" name="collectionobjects_common">
        <objectNumber>Object-$i</objectNumber>
        <distinguishingFeatures>Created by $script_name script</distinguishingFeatures>
        <fieldCollectionPlace>$place_refname</fieldCollectionPlace>
      </schema>
    </import>
RECORD
    print $TEMP_FILEHANDLE $record;

} # end of 'for' loop

print $TEMP_FILEHANDLE &getFooter();

print "Running import command to create $num_to_create new CollectionObject / Cataloging records ...\n";

my @cmd = ("$curl_executable", "-q", "-i", "-u", "admin\@core.collectionspace.org:Administrator",
        "http://localhost:8180/cspace-services/imports",
        "-X", "POST", "-H", "\"Content-Type: application/xml\"",
        "-T", $temp_filename);
print ("@cmd\n") if $verbose;

my $command = join(' ', @cmd);
my $results = `$command 2>&1`;
print("$results\n") if $verbose;
    
close($TEMP_FILEHANDLE); # Erases temporary file

# End of main program

###

sub getHeader {
    my $header = <<HEADER;
<?xml version="1.0" encoding="UTF-8"?>
<imports>
HEADER
    return $header;
}

sub getFooter {
    return "</imports>";
}

sub validateIntegerOptionValue {    
    if (is_positive_integer($_[0])) {
    } else {
        &print_usage();
        exit(0);
    }
}

sub is_positive_integer {
   defined $_[0] && $_[0] =~ /^\d+$/ && int($_[0]) > 0;
}

sub min {
    if($_[0] > $_[1]){
        $_[1];
    } else {
        $_[0];
    }
}

sub print_usage {
    print <<"USAGE";
$script_name [options|-h]
Creates a specified number of CollectionObject / Cataloging records for testing.
Options {explanation} (default value, if any, in parens):
-n or --num_to_create {number of records to create} ($default_num_to_create)
-p or --place_refname {refName for a place term}
-s or --start_value {starting value for object numbers} ($default_start_value)
Other parameters:
-h or --help (prints this help text and exits, regardless of other options)
USAGE
}
