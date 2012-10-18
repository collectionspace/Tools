#!/usr/bin/perl

# Executes a set of SQL command(s) with EXPLAIN ANALYZE, and generates
# reports on their execution times and their environment settings when run.

use strict;
use File::Basename;
use File::Find;
use File::Spec;
use Getopt::Std;
use List::Util qw(min max sum);
use POSIX qw(strftime);

if (@ARGV == 0) {
    print_usage();
    exit 0;
}

# Change the following value to use a different SQL CLI client.
# If you do so, you may also need to tweak one or more relevant commands
# in run_benchmarks(), below.
my $SQL_COMMAND_NAME = 'psql';

my $SQL_COMMAND = undef;
get_sql_command();
defined($SQL_COMMAND) ||
    die "Could not find executable file '$SQL_COMMAND_NAME' to run SQL benchmarks";

my $ANALYZE_OUTPUT_FILE_SUFFIX = '.analyze.txt';

my $opts = {};
getopt('dhnopru', $opts);

if ($opts->{r}) {
	generate_report(
		data_dir => $opts->{r}
	);
}
else {
	my $output_dir = $opts->{o} || 'runs';

	my $db_connection_info = {
		db_host => $opts->{h} || $ENV{DB_HOST} || 'localhost',
		db_user => $opts->{u} || $ENV{DB_USER},
		db_password => $opts->{p} || $ENV{DB_PASSWORD},
		db_name => $opts->{d} || $ENV{DB_NAME} || 'nuxeo'
	};

	my $number_of_runs = $opts->{n} || 10;

	my $run_output_dir = create_run_output_dir($output_dir);
	my @sql_files = get_sql_files(@ARGV);
	
	if (grep {defined($_)} @sql_files) {
	} else {
		print "No SQL files found in the path(s) provided: cannot run benchmarks\n";
		print "Will generate output only for environment settings\n";
	}

	run_benchmarks(
		db_connection_info => $db_connection_info,
		number_of_runs => $number_of_runs,
		output_dir => $run_output_dir,
		sql_files => \@sql_files
	);

	generate_report(
		data_dir => $run_output_dir
	);
}


sub run_benchmarks() {
	my %args = @_;
	my $db_connection_info = $args{db_connection_info};
	my $number_of_runs = $args{number_of_runs};
	my $output_dir = $args{output_dir};
	my $sql_files = $args{sql_files};

	my $db_host = $db_connection_info->{db_host};
	my $db_name = $db_connection_info->{db_name};
	my $db_user = $db_connection_info->{db_user};
	my $db_password = $db_connection_info->{db_password};

	print "Writing output to $output_dir\n";

	my $show_settings_output_file = File::Spec->catfile($output_dir, 'settings.txt');
	my $show_settings_command = "$SQL_COMMAND -U $db_user -d \"host=$db_host password=$db_password dbname=$db_name\" -c \"show all\" >$show_settings_output_file";
	system $show_settings_command;

	my $describe_output_file = File::Spec->catfile($output_dir, 'describe.txt');
	my $describe_command = "$SQL_COMMAND -U $db_user -d \"host=$db_host password=$db_password dbname=$db_name\" -c \"\\d *\" >$describe_output_file";
	system $describe_command;

	my $sysctl_output_file = File::Spec->catfile($output_dir, 'sysctl.txt');
	my $sysctl_command = "sysctl -a >$sysctl_output_file 2>/dev/null";
	system $sysctl_command;
	
	foreach my $run_number (1..$number_of_runs) {
		print "Executing run number $run_number of $number_of_runs\n";
	
		for my $sql_file (@$sql_files) {
			my ($volume, $directories, $file) = File::Spec->splitpath($sql_file); 
			my $output_file = File::Spec->catfile($output_dir, $file . $ANALYZE_OUTPUT_FILE_SUFFIX);
			my $command = "echo 'EXPLAIN (ANALYZE, BUFFERS)' | cat - $sql_file | $SQL_COMMAND -U $db_user -d \"host=$db_host password=$db_password dbname=$db_name\" -f - >>$output_file";

			print "  $sql_file\n";	
			system $command;
		}
	}
}

sub generate_report {
	my %args = @_;
	my $data_dir = $args{data_dir};
	my @run_stats = ();

	opendir(my $dir, $data_dir); 
	my @files = readdir $dir;
	closedir $dir;

	foreach my $file (@files) {
		next unless $file =~ /$ANALYZE_OUTPUT_FILE_SUFFIX$/;	

		push(@run_stats, get_run_stats(File::Spec->catfile($data_dir, $file)));
	}

	print "\n";
	print "-----------------------------------\n";
	print "Report for $data_dir\n";
	print "-----------------------------------\n";

	foreach my $stats (@run_stats) {
		print $stats->{name}, ': ';
		
		if ($stats->{number_of_runs} > 0) {
			print $stats->{number_of_runs}, ' runs, min ', $stats->{min_time}, ' ms, max ', $stats->{max_time}, ' ms, average ', $stats->{average_time}, " ms, deviation ", $stats->{time_std_deviation};
		}
		else {
			print "no runs";
		}

		print "\n";
	}
}

sub get_run_stats {
	my $filename = shift;
	my @times = ();

	open(FILE, '<', $filename) || die "Can't open file: $filename";

	while (<FILE>) {
		next unless /runtime\:\s+([\d\.]+)/;
		push(@times, $1);
	}

	close FILE;

	my ($volume, $directories, $file) = File::Spec->splitpath($filename); 
	$file =~ s/$ANALYZE_OUTPUT_FILE_SUFFIX$//;

	my $average_time = @times > 0 ? (sum(@times)/@times) : 0;
	my $diff_sq_total = 0;

	foreach my $time (@times) {
		$diff_sq_total += ($average_time - $time) ** 2;
	}

	return {
		name => $file,
		number_of_runs => scalar @times,
		min_time => min(@times),
		max_time => max(@times),
		average_time => sprintf('%.3f', $average_time),
		time_std_deviation => sprintf('%.3f', sqrt($diff_sq_total / @times))
	};
}

sub create_run_output_dir {
	my $output_dir = shift;
	my $now_string = strftime('%Y-%m-%d-%H%M%S', localtime());
	my $run_output_dir = "$output_dir/$now_string";

	if (! -d $output_dir) {
	    mkdir $output_dir || die "Directory not found and can't be created: $output_dir";
	}
	mkdir $run_output_dir || die "Can't create directory: $run_output_dir";

	return $run_output_dir;
}

sub get_sql_files {
	my @filespecs = @_;
	my @sql_files = ();

	foreach my $filespec (@filespecs) {
		if (-d $filespec) {
			opendir(my $dir, $filespec);

			while(my $filename = readdir $dir) {
				push(@sql_files, File::Spec->catfile($filespec, $filename)) unless $filename =~ /^\./;
			}

			closedir $dir;
		}
		elsif (-e $filespec) {
			push(@sql_files, $filespec);	
		}
	}

	return @sql_files;
}

sub get_sql_command {
    # Get the path(s) to executable files
    my @PATH = File::Spec->path();
    # Search for the SQL executable within each of those paths
    find(
        {wanted => \&find_sql_executable},
        @PATH);
}

sub find_sql_executable
{
    # Stop descending into subdirectories and stop checking
    # any other files if the SQL executable has already been found
    $File::Find::prune = 1 and return if defined($SQL_COMMAND);
    
    # If the SQL executable was found, set a global variable with its path 
    $SQL_COMMAND = $File::Find::name if
        /^$SQL_COMMAND_NAME$/ && (-x $File::Find::name);
}

# For possible enhancements, see "Help texts" in 
# http://www.vromans.org/johan/articles/getopt.html
sub print_usage {
    my $script_name = basename($0);
    print <<"END_USAGE_INSTRUCTIONS";
$script_name: a database benchmark utility
Executes a set of SQL command(s) with EXPLAIN ANALYZE, and generates
reports on their execution times and their environment settings when run.

Usages:

To run benchmarks:
$script_name [options] sql_file_or_directory
Options (defaults in parens)
-d database_name (DB_NAME environment variable or 'nuxeo')
-h database_host (DB_HOST environment variable or 'localhost')
-n number_of_runs ('10')
-o output_directory ('runs')
-p database_password (DB_PASSWORD environment variable)
-u database_username (DB_USER environment variable)

To (re)run reports on previously-run benchmarks:
$script_name -r existing_benchmark_output_directory
END_USAGE_INSTRUCTIONS
}
