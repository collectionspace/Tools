#!/usr/bin/perl

use strict;
use warnings;

my $MIN_QUERY_LENGTH = 50;

my $stashed_query = "";
open (FILE, "postgresql2.log") or die "Couldn't open PostgreSQL logfile: $!";
while (<FILE>) {

    my $line = $_;

    # Handle lines containing 'SELECT'
    if ($line =~ /.*?PDT LOG:.*?(SELECT.*)/) {
        my $select_statement = $1;
        # print "select=$select_statement\n"; # for debugging
        # If this line contains what appear to be replaceable parameters,
        # stash the query
        
        if ($select_statement =~ /.*?(\$\d{1,3}).*/) {
            $stashed_query = $select_statement;
            # print "stashed_query=$stashed_query\n"; # for debugging
        # Otherwise, print the query
        } else {
            $stashed_query = "";
            print "$select_statement\n" if (length($select_statement) > $MIN_QUERY_LENGTH);
        }

    # Handle lines containing parameter values that should be applied to the
    # replaceable parameters in a just-stashed query
    } elsif (($line =~ /.*?PDT DETAIL:  parameters: (.*)/) && ($stashed_query ne "")) {
        my @parameter_pairs = split(',', $1);
        # print "parameter_pairs=@parameter_pairs\n"; # for debugging
        my $count = 0;
        foreach (@parameter_pairs) {
            my ($replaceable_parameter, $parameter_value) = split(" = ", $_);
            $replaceable_parameter =~ s/^\s*.//;
            # print "replaceable_parameter=$replaceable_parameter\n"; # for debugging
            # print "parameter_value=$parameter_value\n"; # for debugging
            # print "count=$count\n";
            $stashed_query =~  s/\$${replaceable_parameter}/${parameter_value}/;
            # print "stashed_query after $count=$stashed_query\n"; # for debugging
        }
        # Print the query after replacing parameters with their values
        # print "after replacement=";
        print "$stashed_query\n" if (length($stashed_query) > $MIN_QUERY_LENGTH);
        
    } else {
        # Do nothing; this line of the logfile isn't of interest
    }
    
}
close FILE;

=begin COMMENTS
foreach (@parameter_pairs) {
            @each_param = split(" = ", $_);
            $parameters{$each_param[0]} = $each_param[1];
             print "$parameters\n";
        } 
if contains PDT LOG:
  Take everything after that
  Take everything from the start of (must be capitalized, as per Nuxeo and reports) SELECT to EOL.
  Discard if doesn't meet length threshold
  Write to disk if doesn't contain replaceable parameters
if contains PDT DETAIL:  parameters:
  Take everything after that
  Split on comma separators
  Split on ' = ' separators
  $1 = 'admin@lifesci.collectionspace.org', $2 = '2'
=end COMMENTS