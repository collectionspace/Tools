#!/usr/bin/perl

# Extracts a set of SQL SELECT queries from a PostgreSQL database logfile.

use strict;
use warnings;
use File::Basename;
use Getopt::Std;
use POSIX qw(strftime);

# Whether to echo printing of SELECT queries to the console.
# Set to '1' when doing interactive debugging.
my $echo_to_console = 1;

my $DEFAULT_MIN_QUERY_LENGTH = 50;
my $SELECT_STATEMENT_REGEX = ".*?PDT LOG:.*?(SELECT.*)";
my $CONTAINS_REPLACEABLE_PARAMS_REGEX = ".*?(\\\$[0-9]{1,3}).*";
my $PARAMETER_VALUES_REGEX = ".*?PDT DETAIL:  parameters: (.*)";

my %options=();
getopt('d:L:', \%options);

# Pathname of PostgreSQL logfile to open
#(assumed to be in local directory if no path provided)
my $logfile_name = $ARGV[0] || 'postgresql.log';

# Output directory to which query files will be written
my $output_dir = $options{d} || 'sql';
my $query_output_dir = create_query_output_dir($output_dir);

# Minimum length for queries of interest; shorter queries will be filtered out
my $min_query_length = $options{L} || $DEFAULT_MIN_QUERY_LENGTH;

my $stashed_query = "";
my $query_number = 0;

open (LOGFILE, $logfile_name) or die "Couldn't open PostgreSQL logfile $logfile_name: $!";
while (<LOGFILE>) {

    my $current_line = $_;

    # Handle lines containing 'SELECT'
    if ($current_line =~ /$SELECT_STATEMENT_REGEX/) {
        my $select_statement = $1;
        # If this line contains what appear to be replaceable parameters,
        # stash away the query, at least until the next line is read and
        # its values can be inserted in place of those parameters
        if ($select_statement =~ /$CONTAINS_REPLACEABLE_PARAMS_REGEX/) {
            $stashed_query = $select_statement;
        # Otherwise, print the query
        } else {
            if (length($select_statement) > $min_query_length) {
                $stashed_query = "";
                $query_number++;
                print_query("$select_statement", $query_number, $query_output_dir);
            }
        }

    # Handle lines containing parameter values that should be applied to the
    # replaceable parameters in a just-stashed query
    } elsif (($current_line =~ /$PARAMETER_VALUES_REGEX/) && ($stashed_query ne "")) {
        my @parameter_pairs = split(',', $1);
        my $count = 0;
        foreach (@parameter_pairs) {
            my ($replaceable_parameter, $parameter_value) = split(" = ", $_);
            # Strip leading whitespace and the leading dollar sign from the string to match
            $replaceable_parameter =~ s/^\s*.//;
            $stashed_query =~  s/\$${replaceable_parameter}/${parameter_value}/;
        }
        # Print the query after replacing parameters with their values
        if (length($stashed_query) > $min_query_length) {
            $query_number++;
            print_query("$stashed_query", $query_number, $query_output_dir);
        }
    } else {
        # Do nothing; this line of the logfile isn't of interest
    }
    
}
close LOGFILE;

sub print_query {
    my $select_statement = shift;
    my $query_number = shift;
    my $query_output_dir = shift;
    if ($echo_to_console) {
        print "$select_statement\n";
    }
}

# Borrowed from db_benchmark.pl script
sub create_query_output_dir {
	my $output_dir = shift;
	my $now_string = strftime('%Y-%m-%d-%H%M%S', localtime());
	my $query_output_dir = "$output_dir/$now_string";
	if (! -d $output_dir) {
	    mkdir $output_dir || die "Directory not found and can't be created: $output_dir $!";
	}
	mkdir $query_output_dir || die "Can't create directory: $query_output_dir $!";
	return $query_output_dir;
}

sub print_usage {
    my $script_name = basename($0);
    print <<"END_USAGE_INSTRUCTIONS";
$script_name:
Extracts a set of SQL SELECT queries from a PostgreSQL database logfile.

Usage:

$script_name [options] logfile
Options (defaults in parens)
-d name of output directory within the current directory (sql)
-L minimum length in chars of any SELECT queries to be exacted (50)
or
--help  prints this set of help instructions, then exits without running script
END_USAGE_INSTRUCTIONS
}
