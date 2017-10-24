#!/usr/bin/perl

use strict;
use Cwd;
use Date::Format;
use File::Spec;
use JSON qw(decode_json);

my $CWD = getcwd();
my @PROJECTS = qw(services application ui);
my $UI_APPCACHE_FILE = 'src/main/webapp/tenants/%s/cspace.appcache';
my $UI_MESSAGES_FILE = 'src/main/webapp/tenants/%s/bundle/core-messages.properties-overlay';
my $UI_FOOTER_FILE = 'src/main/webapp/tenants/%s/js/Footer.js';
my $RELEASE_NOTES_FILE = 'src/main/webapp/tenants/%s/html/releaseNotes.html';

make_release($ARGV[0]);

sub make_release {
	my $release_branch = determine_release_branch();
	my $version_number = shift || determine_version_number($release_branch);
		
	print "making release tag $version_number from branch $release_branch\n";
	
	# TODO: Check for uncommitted changes, and prompt/warn/fail if there are any
	
	update_ui_version_numbers($version_number);
	generate_release_notes($release_branch, $version_number);
	
	print "\nUI files have been edited. Use git diff to verify the changes. Commit and tag? (y/N) ";
	
	my $continue = <STDIN>;
	chomp($continue);
	
	if (uc($continue) ne 'Y') {
		print "aborting\n";
		exit;
	}
	
	commit_ui_updates($version_number);
	create_tags($release_branch, $version_number);
	
	print "\nChanges have been committed, and the release has been tagged. Push to github? (y/N) ";

	my $continue = <STDIN>;
	chomp($continue);
	
	if (uc($continue) ne 'Y') {
		print "aborting\n";
		exit;
	}
	
	push_branches($release_branch);
	push_tags();
}

sub determine_release_branch {
	my %branches = ();
	
	foreach my $project (@PROJECTS) {
		chdir_to_project($project);
		
		my $current_branch_name = `git symbolic-ref --short HEAD`;
		chomp $current_branch_name;
		
		if (!$current_branch_name) {
			die "could not determine the branch to use for the release: $project is not on any branch";
		}

		$branches{$current_branch_name} = 1;
	}

	chdir $CWD;

	if (scalar(keys(%branches)) != 1) {
		die 'could not determine the branch to use for the release (could be ' . join(" or ", keys(%branches)) . ')';
	}
	
	return (keys(%branches))[0];
}

sub determine_version_number {
	my $branch = shift;
	my $remote_branch = get_remote_branch($branch);
	my $last_revision = 0;
	
	foreach my $project (@PROJECTS) {
		chdir_to_project($project);
			
		my @tags = `git tag --list $remote_branch-*`;

		foreach my $tag (@tags) {
			my @parts = split(/-/, $tag);
			my $revision = pop(@parts);
			my $branch = join('-', @parts);
	
			if ($revision > $last_revision) {
				$last_revision = $revision;
			}
		}
	}

	chdir $CWD;
	
	my $revision = $last_revision + 1;
	my $remote_branch = get_remote_branch($branch);
	
	return "$remote_branch-$revision";
}

sub update_ui_version_numbers {
	my $version_number = shift;
	my $tenant_id = (split(/_/, $version_number))[0];
	my $ui_appcache_file = sprintf($UI_APPCACHE_FILE, $tenant_id);
	my $ui_messages_file = sprintf($UI_MESSAGES_FILE, $tenant_id);
	my $ui_footer_file = sprintf($UI_FOOTER_FILE, $tenant_id);
	
	chdir_to_project('ui');
	
	# TODO: If any of the files are already modified, prompt/warn/fail.
	# TODO: If the tenant cspace.appcache doesn't exist, create it.
	# TODO: If the tenant messages file doesn't exist, create it.
	# TODO: If the tenant footer.js doesn't exist, create it.
	# TODO: If the tenant releaseNotes.html doesn't exist, create it.
		
	system "perl -pi -e 's/^# Version:.*/# Version: $version_number/' $ui_appcache_file";
	system "perl -pi -e 's/^login-deployment:.*/login-deployment: Version $version_number/' $ui_messages_file";
	system "perl -pi -e 's/deploymentVersion:.*/deploymentVersion: \"$version_number\",/' $ui_footer_file";

	# Verify that the files were changed.
	
	my @status_lines = `git status --short`;
	my %modified_files = ();
	
	foreach my $status_line (@status_lines) {
		if ($status_line =~ /\s+M\s+(.*)/) {
			my $modified_file = $1;
			$modified_files{$modified_file} = 1;
		}
	}
	
	foreach my $expected_file ($ui_appcache_file, $ui_messages_file, $ui_footer_file) {
		if (!$modified_files{$expected_file}) {
			die "$expected_file should have been modified, but wasn't";
		}
	}

	chdir $CWD;
}

sub commit_ui_updates {
	my $version_number = shift;
	
	chdir_to_project('ui');

	system "git commit -a -m 'NOJIRA: (make-release) Update version numbers to $version_number and generate release notes.'";	

	chdir $CWD;
}

sub generate_release_notes {
	my $release_branch = shift;
	my $version_number = shift;
	my $tenant_id = (split(/_/, $version_number))[0];
	my $release_notes_file = sprintf($RELEASE_NOTES_FILE, $tenant_id);
	my $last_version_number = get_last_release_notes_version_number($release_notes_file);

	die("couldn't determine last version when generating release notes") unless ($last_version_number);

	my %changes_by_issue_number = ();

	foreach my $project (@PROJECTS) {
		chdir_to_project($project);
			
		my @git_log = `git log --no-merges --format='%h %at %s' $last_version_number..$release_branch`;
	
		foreach my $line (@git_log) {
			chomp $line;
		
			die("unexpected git log entry '$line'") unless ($line =~ /^([a-f0-9]+)\s+(\d+)\s+(.*)$/);
		
			my $commit_id = $1;
			my $timestamp = $2;
			my $log_message = $3;
			my $issue_numbers = '';
		
			if ($log_message =~ /^(\S+):\s+(.*)$/) {
				($issue_numbers, $log_message) = split(/:\s+/, $log_message, 2);
			}
			
			my ($issue_number) = split(/,/, $issue_numbers);

			if (!$issue_number) {
				$issue_number = 'NOJIRA';
			}
			
			if (!defined($changes_by_issue_number{$issue_number})) {
				$changes_by_issue_number{$issue_number} = [];
			}
			
			push($changes_by_issue_number{$issue_number}, {
				project => $project,
				timestamp => $timestamp,
				commit_id => $commit_id,
				issue_number => uc($issue_number),
				log_message => $log_message
			});
		}
		
		chdir $CWD;
	}
	
	my @html_sections = ();
	my $nojira_html_section = undef;
	
	foreach my $issue_number(sort(keys(%changes_by_issue_number))) {
		my $issue_summary = '';
		
		if ($issue_number eq 'NOJIRA') {
			$issue_summary = 'Other changes';
		}
		else {
			$issue_summary = get_jira_summary($issue_number) || warn("failed to get summary for issue $issue_number");
		}
		
		my $html = $issue_summary;
		
		if ($issue_number ne 'NOJIRA') {
			$html .= qq( <span class="issuenumber">(<a href="https://issues.collectionspace.org/browse/$issue_number">$issue_number</a>)</span>);
		}

		$html .= "\n";
		
		my @commits = sort {$a->{timestamp} <=> $b->{timestamp}} @{$changes_by_issue_number{$issue_number}};
		
		if (scalar(@commits) > 0) {
			$html .= qq(<ul class="commits">\n);
			
			foreach my $commit (@commits) {
				$html .= qq(<li id="commit_$commit->{commit_id}" class="$commit->{project} commit">$commit->{log_message}</li>\n);
			}
			
			$html .= "</ul>\n"
		}
		
		if ($issue_number eq 'NOJIRA') {
			$nojira_html_section = $html;
		}
		else {
			push(@html_sections, $html);
		}
	}
	
	if ($nojira_html_section) {
		push(@html_sections, $nojira_html_section);
	}
	
	my $release_date = time2str('%B %e, %Y', time);
	my $html = '';
	
	$html .= qq(<div id="$version_number">\n);
	$html .= qq(<h2>Version $version_number <span class="releasedate">($release_date)</span></h2>\n);
	$html .= qq(<p class="auto-generation warning">These release notes were automatically generated, and have not been edited. Please contact <a href="mailto:cspace-support\@lists.berkeley.edu">cspace-support\@lists.berkeley.edu</a> if you have questions about this release.</p>\n);
	$html .= qq(<p class="description">This release of CollectionSpace addresses the following issues:</p>\n);
	$html .= qq(<ul class="issues">\n);
	
	foreach my $section (@html_sections) {
		$html .= qq(<li class="issue">\n);
		$html .= qq($section);
		$html .= qq(</li>\n);
	}
	
	$html .= qq(</ul>\n);
	$html .= qq(</div>\n);
	
	update_release_notes($release_notes_file, $version_number, $html);
	
	# Verify that the file was changed.
	
	chdir_to_project('ui');
	
	my @status_lines = `git status --short`;
	my $changed = 0;
	
	foreach my $status_line (@status_lines) {
		if ($status_line =~ /\s+M\s+(.*)/) {
			my $modified_file = $1;
			
			if ($modified_file eq $release_notes_file) {
				$changed = 1;
				last;
			}
		}
	}
	
	chdir $CWD;
	
	if (!$changed) {
		die "$release_notes_file should have been modified, but wasn't";
	}
}

sub get_jira_summary {
	my $issue_number = shift;
	my $url = "https://issues.collectionspace.org/rest/api/2/issue/$issue_number?fields=summary";	
	
	my $response = decode_json(`curl -s $url`);
	my $summary = $response->{fields}->{summary};
	
	return $summary;
}

sub get_last_release_notes_version_number {
	my $release_notes_file = shift;
	my $last_version_number;

	chdir_to_project('ui');

	open(my $file, "<", $release_notes_file) || die "can't find release notes file $release_notes_file";
	
	while (<$file>) {
		if (/generated_release_notes\((.*?)\)/) {
			$last_version_number = $1;
			last;
		}
	}
	
	close $file;
	
	chdir $CWD;
	
	return $last_version_number;
}

sub update_release_notes {
	my $release_notes_file = shift;
	my $version_number = shift;
	my $html = shift;
	my $temp_release_notes_file = "$release_notes_file.tmp";
	
	chdir_to_project('ui');

	open(my $input_file, "<", $release_notes_file) || die "can't find release notes file $release_notes_file";
	open(my $output_file, ">", $temp_release_notes_file) || die "can't open temp release notes file $temp_release_notes_file";
	
	while (<$input_file>) {
		if (/generated_release_notes\(.*?\)/) {
			print {$output_file} "<!-- generated_release_notes($version_number) -->\n";
			print {$output_file} $html;
			print {$output_file} $_;
			
			last;
		}
		else {
			print {$output_file} $_;
		}
	}

	while (<$input_file>) {
		print {$output_file} $_;
	}
	
	close $input_file;
	close $output_file;

	rename($temp_release_notes_file, $release_notes_file);
	
	chdir $CWD;
}

sub push_branches {
	my $release_branch = shift;
	my $remote_release_branch = get_remote_branch($release_branch);
	my $cspace_version = (split(/_/, $remote_release_branch))[1];

	foreach my $project (@PROJECTS) {
		chdir_to_project($project);
		
		system "git push";
		system "git push cspace-deployment $release_branch:$remote_release_branch";
		system "git push cspace-deployment cspace-deployment_v$cspace_version:refs/heads/v$cspace_version";
	}

	chdir $CWD;	
}

sub create_tags {
	my $release_branch = shift;
	my $version_number = shift;
	my $remote_release_branch = get_remote_branch($release_branch);
		
	foreach my $project (@PROJECTS) {
		chdir_to_project($project);
		
		system "git tag -a $version_number -m 'Release tag of the $remote_release_branch branch.'";
	}

	chdir $CWD;	
}

sub push_tags {
	foreach my $project (@PROJECTS) {
		chdir_to_project($project);
		
		system "git push --tags";
		system "git push --tags cspace-deployment";
	}

	chdir $CWD;	
}

sub chdir_to_project {
	my $project = shift;
	my $project_dir = get_project_dir($project);
	
	die "can't find $project project at $project_dir" unless (-d $project_dir);
	
	chdir $project_dir;
}

sub get_project_dir {
	my $project = shift;
	
	return File::Spec->catdir($CWD, $project);
}

sub get_remote_branch {
	my $local_branch = shift;
	my $remote_branch = $local_branch;

	# My latest convention is to prepend the local branch name with "cspace-deployment_".
	# Remove that prefix to get the name of the branch on cspace-deployment.
	
	$remote_branch =~ s/^cspace-deployment_//;

	return $remote_branch;
}