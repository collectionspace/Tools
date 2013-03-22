#!/usr/bin/perl

# Extracts a set of SQL SELECT queries from a PostgreSQL database logfile.
# Fills in the values of replaceable parameters in those queries, as needed.

use strict;
use warnings;

use File::Basename;
use File::Spec;
use Getopt::Std;
use POSIX qw(strftime);

# Whether to echo printing of SELECT queries to the console.
# Set to '1' when doing interactive debugging.
my $echo_to_console = 0;

my $DEFAULT_QUERY_FILENAME = "query";
my $DEFAULT_SQL_FILENAME_EXTENSION = ".sql";
my $SELECT_STATEMENT_REGEX = ".*?PDT LOG:.*?(SELECT.*)";
my $CONTAINS_REPLACEABLE_PARAMS_REGEX = ".*?(\\\$[0-9]{1,3}).*";
my $PARAMETER_VALUES_REGEX = ".*?PDT DETAIL:  parameters: (.*)";

my $DEFAULT_OUTPUT_DIR_NAME = "sql";
my $DEFAULT_MIN_QUERY_LENGTH = 200;
my $DEFAULT_NUM_QUERIES_TO_EXTRACT = 1000;

my %options=();
getopt('d:n:L:', \%options);

# Pathname of PostgreSQL logfile to open
#(assumed to be in local directory if no path provided)
my $logfile_name = $ARGV[0]; # || 'postgresql.log';
if (! defined $logfile_name || $logfile_name eq "") {
    print_usage();
    exit(0);
}

# Output directory to which query files will be written
my $output_dir = $options{d} || $DEFAULT_OUTPUT_DIR_NAME;
my $query_output_dir = create_query_output_dir($output_dir);

# Number of queries to extract
my $num_queries_to_extract = $options{n} || $DEFAULT_NUM_QUERIES_TO_EXTRACT;

# Minimum length for queries of interest; shorter queries will be filtered out
my $min_query_length = $options{L} || $DEFAULT_MIN_QUERY_LENGTH;

my $stashed_query = "";
my $query_count = 0;

open (LOGFILE, "<", $logfile_name) or die "Couldn't open PostgreSQL logfile $logfile_name: $!";
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
                $query_count++;
                print_query("$select_statement", $query_count, $query_output_dir);
            }
        }

    # Handle lines containing parameter values that should be applied to the
    # replaceable parameters in a just-stashed query
    } elsif (($current_line =~ /$PARAMETER_VALUES_REGEX/) && ($stashed_query ne "")) {
        my @parameter_pairs = split(',', $1);
        foreach (@parameter_pairs) {
            my ($replaceable_parameter, $parameter_value) = split(" = ", $_);
            # Strip leading whitespace and the leading dollar sign from the string to match
            $replaceable_parameter =~ s/^\s*.//;
            $stashed_query =~  s/\$${replaceable_parameter}/${parameter_value}/;
        }
        # Print the query after replacing parameters with their values
        if (length($stashed_query) > $min_query_length) {
            $query_count++;
            print_query("$stashed_query", $query_count, $query_output_dir);
        }
    } else {
        # Do nothing; this line of the logfile isn't of interest
    }
    
    if (($num_queries_to_extract > 0) && ($query_count >= $num_queries_to_extract)) {
        last;
    }
    
}
close LOGFILE;
print "Wrote $query_count SELECT queries within directory $query_output_dir ...\n";

sub print_query {
    my $select_statement = shift;
    my $query_count = shift;
    my $query_output_dir = shift;
    if ($echo_to_console) {
        print "$select_statement\n";
    }
    my $query_filename = $DEFAULT_QUERY_FILENAME . $query_count . $DEFAULT_SQL_FILENAME_EXTENSION;
    my $query_filepath = File::Spec->catfile($query_output_dir, $query_filename);
    open (QUERYFILE, ">", "$query_filepath") ||
        die "Could not create PostgreSQL query file $query_filepath: $!";
    print QUERYFILE "$select_statement\n";
    close(QUERYFILE);
}

# Borrowed from db_benchmark.pl script
sub create_query_output_dir {
	my $output_dir = shift;
	my $now_string = strftime('%Y-%m-%d-%H%M%S', localtime());
	my $query_output_dir = "$output_dir/$now_string";
	if (! -d $output_dir) {
	    mkdir $output_dir ||
	        die "Could not find or create query output directory $output_dir: $!";
	}
	mkdir $query_output_dir ||
	    die "Can't create query output directory $query_output_dir: $!";
	return $query_output_dir;
}

sub print_usage {
    my $script_name = basename($0);
    print <<"END_USAGE_INSTRUCTIONS";
$script_name:
Extracts a set of SQL SELECT queries from a PostgreSQL database logfile.
Fills in the values of replaceable parameters in those queries, as needed.

Usage:

$script_name [options] logfile
Options (defaults in parens)
-d path to output directory to be created (./$DEFAULT_OUTPUT_DIR_NAME)
-n number of queries to extract ($DEFAULT_NUM_QUERIES_TO_EXTRACT)
-L minimum length in chars of any SELECT queries to be extracted ($DEFAULT_MIN_QUERY_LENGTH)
or
--help  prints this set of help instructions, then exits without running script
END_USAGE_INSTRUCTIONS
}
