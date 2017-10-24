#!/usr/bin/perl

use strict;

use File::Find;
use Date::Format qw(time2str);
use HTTP::Date qw(str2time);
use Text::CSV;
use URI::Escape;

#
# Process the supplied directory of tomcat log files, finding autocomplete queries to the app layer.
# Print the parsed data in csv format to standard out.
#
process_log_dir($ARGV[0]);

sub process_log_dir {
	my $log_dir = shift;
	my @log_files;

	find(sub {
		push(@log_files, $File::Find::name) if (-f && /\.txt$/)
	}, $log_dir);

	my $stdout = *STDOUT;
	my $csv = Text::CSV->new({
		eol => "\n"
	});

	$csv->print($stdout, ['Timestamp', 'Before/After 3.2.2 Upgrade?', 'Record Type', 'Field', 'Search Term', 'Response Code', 'Time Elapsed (s)']);

	foreach my $file (sort(@log_files)) {
		process_log_file($file, $csv);	
	}

	#process_log_file($log_files[0]);
}

sub process_log_file {
	my $log_file = shift;
	my $csv = shift;
	my $stdout = *STDOUT;
	my $upgrade_time = str2time('23/Apr/2013:00:00:00 -0700');

	if (open(LOGFILE, $log_file)) {
		foreach my $line (<LOGFILE>) {
			chomp($line);
		
			if ($line =~ /^(.*?) (.*?) (.*?) \[(.*?)\] "(.*?)" (.*?) (.*?) (.*?)$/) {
				my $timestamp = $4;
				my $url = $5;
				my $response_code = $6;
				my $elapsed = $8;

				if ($url =~ /\/collectionspace\/tenant\/.*?\/(vocabularies\/)?(.*?)\/autocomplete\/(.*?)\?q=(.*?)[& ]/) {
					my $record_type = $2;
					my $field_name = $3;
					my $term = uri_unescape($4);

					# Skip term completion on cataloging broader and narrower context, since this wasn't affected by the 3.2.2 changes.

					if (!($record_type eq 'cataloging' && ($field_name eq 'narrowerContext' || $field_name eq 'broaderContext'))) {
						my $time = str2time($timestamp);

						$csv->print($stdout, [time2str('%c', $time), $time < $upgrade_time ? 'before' : 'after', $record_type, $field_name, $term, $response_code, $elapsed]);
					}
				}
			}
			else {
				warn ("Failed to parse log entry: $line");
			}
		}

		close(LOGFILE);
	}
	else {
		warn("Failed to open file: $log_file");
	}
}
