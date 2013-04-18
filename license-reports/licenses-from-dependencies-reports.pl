#!/usr/bin/perl
use File::Basename;
use File::Find;
use Getopt::Long;

use strict;

my %licenses = (); 
my %normalized_licenses = populate_normalized_licenses();

my $html = '';
my $normalize = 1;
my $default_separator = ' | ';
my $separator = $default_separator;
my $text = '';
GetOptions ('html' => \$html, 'normalize!' => \$normalize, 'separator=s' => \$separator, 'text' => \$text);
if ($text eq '' && $html eq '') {
  &print_usage;
}
if ($text ne '' && $html ne '') {
  print "Please choose only one output option.\n\n";
  &print_usage;
}

find(\&read_file, ".");

print_result(\%licenses) if $text;
print_html(\%licenses) if $html;

####
# read_file:
#
# takes a filename, checks if it ends in html or htm
# and if so, read's it and calls the function
# parse_file with the content.
# any files that does not end in htm(l) is ignored
####
sub read_file {
    my $file = $_;

    #only read html and htm files, ignore everything else
    if (-f $file && $file =~ m/\.html?$/i) {
        print STDERR "READING: $file\n";
        my $file_contents; #this will hold file contents
        #read the file contents
        open(FILE, "<$file"); 
        $file_contents = do { local $/; <FILE> }; #read content
        close(FILE);
        #call parse_file with content
        parse_file($file_contents);
    }
}

####
# parse_file
#
# Takes the content of a file and parses it
# The actual parsing is done in a different 
# function
####
sub parse_file {
    my ($content) = @_;
    parse_license_section($content);
}

####
# print_html
#
# Takes a reference to a hash of hashes,
# sorts both outer hash and for each of those
# the inner hash, based on indexes. Then prints 
# them in a table for each outerkey in the format
# <h3>outerkey1</h3>
# <table>
# <tr><td>innerkey1.1</td><td>outerkey1</td></tr>
# <tr><td>innerkey1.2</td><td>outerkey1</td></tr>
# <tr><td>innerkey1.3</td><td>outerkey1</td></tr>
# </table>
# <h3>outerkey2</h3>
# (...)
# outerkeyn --- innerkeyn.m
####
sub print_html  {
    my ($licenses_ref) = @_;
    my %licenses = %{$licenses_ref};
    print "<html><body><h1>License Dependencies</h1>\n";
    #make a hash variable based on reference and step through sorted
    foreach my $key (sort (keys(%licenses))) {
        print "<h3>$key</h3>\n";
        print "<table border=1 width='80%'>\n";
        print "<tr style='background-color:#CCCCCC'><td>Artifact</td><td>License</td>\n";
           #loop through keys in inner hash
        my %artifacts = %{$licenses{$key}};
        foreach my $art_key (sort (keys(%artifacts))) {
            next if &matches_collectionspace_package($art_key);
            print "<tr><td style='width:50%'>$art_key</td><td>$key</td></tr>\n";
        }
        print "</table><BR>\n";
    }
    print "</body></html>";
}

####
# print_result
#
# Takes a reference to a hash of hashes,
# sorts both outer hash and for each of those
# the inner hash, based on indexes. Then prints 
# them in the format
# outerkey1 --- innerkey1.1
# outerkey1 --- innerkey1.2
# outerkey2 --- innerkey2.1
# outerkey2 --- innerkey2.2
# (...)
# outerkeyn --- innerkeyn.m
####
sub print_result  {
    my ($licenses_ref) = @_;
    my %licenses = %{$licenses_ref};
    #make a hash variable based on reference and step through sorted
    foreach my $key (sort (keys(%licenses))) {
           #loop through keys in inner hash
        my %artifacts = %{$licenses{$key}};
        foreach my $art_key (sort (keys(%artifacts))) {
             next if &matches_collectionspace_package($art_key);
             print "$key";
             print $separator;
             print "$art_key\n";
        }
    }
}

####
# parse_license_section
#
# Takes the content of a file and parses the
# entire Licenses section. Each License name
# is used as key in an outer hash. Each outer hash 
# contains an innner hash that holds the artifacts
# that are released under the license. The artifact
# names are keys of the inner hash
####
sub parse_license_section {
    my ($content) = @_;
        #match the Licenses section of the page:
        # - match from <h2>[any spaces]Licenses
    # - greedy match to next <h2 (that is, section)
        #my @matches = $content =~  m#<h2>\s*Licenses.*(<b>.*</p>)+<h2#gsi;
        $content =~  m#<h2>\s*Licenses(.*?)<h2#gsi;
    my $license_section = $1;
    while ($license_section =~ m#<b>(.*?):\s*</b>(.*?)</p>#gsi) {
        #lowercase license name, so hashing (and later sorting) wont be case-sensitive
        my $license = lc($1);
        if ($normalize) {
            $license = &normalize_license($license);
        }
        my $artifact_group = $2;
        if (!$licenses{$license}) {
            #Create anonymous hash and have $licenses{$license} reference it 
            $licenses{$license} = {};
        } 
        while ($artifact_group =~ m#\s*([^,]+)\s*#gsi) {
            $licenses{$license}->{$1} = 1;
        }
    }
}

sub normalize_license {
    my ($license) = @_;
    if ($normalized_licenses{$license}) {
        return $normalized_licenses{$license};
    } else {
        return $license;
    }
}

sub matches_collectionspace_package {
    my ($artifact) = @_;
    # Patterns used by the Services layer's code
    if ($artifact =~ /^services\..*/) {
        return 1;
    } elsif ($artifact =~ /^org\.collectionspace.*/) {
        return 1;
    # Patterns used by the Application layer's code
    } elsif ($artifact =~ /^Collection-Space.*/) {
        return 1;
    } elsif ($artifact =~ /^Core$/) {
        return 1;
    } elsif ($artifact =~ /^CSP: .*/) {
        return 1;
    } else {
        return 0;
    }
}

# Most of the presumably canonical license names below come from
# The Open Source Initiative:
# http://opensource.org/licenses (most commonly used licenses)
# http://opensource.org/licenses/alphabetical (a more extensive list)
#
# Canonical names for licenses vary maddeningly, with minor variations
# of content, capitalization, punctuation, and abbreviation
# on both the above site and on the websites of each of the
# license-promulgating organizations. The following is a best
# effort and represents our own internal standarization.

# See also this helpful characterization of license terms from the
# Kuali Foundation:
# https://wiki.kuali.org/display/KULFOUND/3rd+Party+Licenses

# FIXME: We may wish to substitute regex matching, for enhanced
# flexibility and reduced maintenance at the risk of some inaccuracy,
# relative to these hand-tuned match strings.

sub populate_normalized_licenses{
    my %normalized_licenses = ();

    # http://opensource.org/licenses/Apache-2.0
    $normalized_licenses{'apache 2'} = "Apache License, Version 2.0"; 
    $normalized_licenses{'apache license version 2'} = "Apache License, Version 2.0";
    $normalized_licenses{'apache license version 2.0'} = "Apache License, Version 2.0";
    $normalized_licenses{'apache license, version 2.0'} = "Apache License, Version 2.0";
    $normalized_licenses{'apache software license - version 2.0'} = "Apache License, Version 2.0";
    $normalized_licenses{'asf 2.0'} = "Apache License, Version 2.0";
    $normalized_licenses{'the apache software license, version 2.0'} = "Apache License, Version 2.0";
    # The only instance of this ambiguous license name encountered to date was HttpClient,
    # in Application layer dependencies, which was verified to use the version 2.0 license
    # per http://hc.apache.org/httpclient-legacy/license.html
    $normalized_licenses{'apache license'} = "Apache License, Version Unspecified";
    $normalized_licenses{'apache-style license'} = "Apache-style License";
    
    # http://www.bouncycastle.org/licence.html
    # Although not titled as such on the above page, the name "Bouncy Castle License"
    # is widely used in references to this license.
    $normalized_licenses{'bouncy castle licence'} = "Bouncy Castle License";
    $normalized_licenses{'bouncy castle license'} = "Bouncy Castle License";

    # http://opensource.org/licenses/BSD-3-Clause
    # http://opensource.org/licenses/BSD-2-Clause
    $normalized_licenses{'bsd'} = "BSD License, Version Unspecified";
    $normalized_licenses{'bsd licence'} = "BSD License, Version Unspecified";
    $normalized_licenses{'bsd license'} = "BSD License, Version Unspecified";
    $normalized_licenses{'bsd style'} = "BSD-style License";
    $normalized_licenses{'bsd-style license'} = "BSD-style License";
    
    $normalized_licenses{'cddl license'} = "Common Development and Distribution License, Version Unspecified";

    # http://opensource.org/licenses/CDDL-1.0
    $normalized_licenses{'cddl 1.0'} = "Common Development and Distribution License, Version 1.0 (CDDL-1.0)";
    $normalized_licenses{'common development and distribution license (cddl) v1.0'} = "Common Development and Distribution License, Version 1.0 (CDDL-1.0)";
    $normalized_licenses{'common development and distribution license (cddl) version 1.0'} = "Common Development and Distribution License, Version 1.0 (CDDL-1.0)";
    # http://jsp.java.net/
    # The current version of JSP now uses a dual license, CDDL 1.1 plus GPL 2
    $normalized_licenses{'cddl + gplv2 with classpath exception'} = "Common Development and Distribution License, Version 1.0 (CDDL-1.0) plus GNU General Public License, Version 2 (GPL-2.0) with Classpath Exception (dual license)";
    # http://jax-ws.java.net/
    # The current version of the JAX-WS Reference Implementation now uses a dual license, CDDL 1.1 plus GPL 2
    $normalized_licenses{'dual license consisting of the cddl v1.0 and gpl v2'} = "Common Development and Distribution License, Version 1.0 (CDDL-1.0) plus GNU General Public License, Version 2 (GPL-2.0) (dual license)";

    # http://spdx.org/licenses/CDDL-1.1
    # http://jaxb.java.net/
    # The current version of JAXB and its associated packages now use a dual license, CDDL 1.1 plus GPL 2
    $normalized_licenses{'cddl 1.1'} = "Common Development and Distribution License, Version 1.1 (CDDL-1.1)";

    # http://opensource.org/licenses/cpl1.0.php
    $normalized_licenses{'common public license version 1.0'} = "Common Public License, Version 1.0 (CPL-1.0)";

    # http://opensource.org/licenses/EPL-1.0
    $normalized_licenses{'eclipse public license - v 1.0'} = "Eclipse Public License, Version 1.0 (EPL-1.0)";
    $normalized_licenses{'eclipse public license - version 1.0'} = "Eclipse Public License, Version 1.0 (EPL-1.0)";
    
    # GNU GPL-family licenses
    $normalized_licenses{'gnu general public library'} = "GNU General Public License, Version Unspecified";
    $normalized_licenses{'gpl license'} = "GNU General Public License, Version Unspecified";
    $normalized_licenses{'the gnu general public license, version 2'} = "GNU General Public License, Version Unspecified";
    # http://opensource.org/licenses/GPL-2.0
    # http://www.gnu.org/software/classpath/license.html
    $normalized_licenses{'gpl2 w/ cpe'} = "GNU General Public License, Version 2 (GPL-2.0) with Classpath Exception";
    $normalized_licenses{'gplv2 with classpath exception'} = "GNU General Public License, Version 2 (GPL-2.0) with Classpath Exception";

    # GNU LGPL-family licenses
    # http://opensource.org/licenses/lgpl-3.0.html
    $normalized_licenses{'gnu lesser general public license, version 3'} = "GNU Lesser General Public License, Version 3 (LGPL-3.0)";
    $normalized_licenses{'gnu lesser general public license, version 3 or later'} = "GNU Lesser General Public License, Version 3 (LGPL-3.0)";
    # http://opensource.org/licenses/lgpl-2.1.php
    $normalized_licenses{'gnu lesser general public license, 2.1'} = "GNU Lesser General Public License, Version 2.1 (LGPL-2.1)";
    $normalized_licenses{'gnu lesser general public license, version 2.1'} = "GNU Lesser General Public License, Version 2.1 (LGPL-2.1)";
    $normalized_licenses{'lesser gnu public license (lgpl), version 2.1'} = "GNU Lesser General Public License, Version 2.1 (LGPL-2.1)";
    $normalized_licenses{'lgpl 2.1'} = "GNU Lesser General Public License, Version 2.1 (LGPL-2.1)";
    $normalized_licenses{'lgpl version 2.1'} = "GNU Lesser General Public License, Version 2.1 (LGPL-2.1)";
    # GNU Trove is licensed under an LGPL 2.1 (or later) license
    # http://trove4j.sourceforge.net/html/license.html
    $normalized_licenses{'trove'} = "GNU Lesser General Public License, Version 2.1 (LGPL-2.1)";
    # Unspecified version(s)
    $normalized_licenses{'gnu lesser general public licence'} = "GNU Lesser General Public License, Version Unspecified (LGPL)";
    $normalized_licenses{'gnu lesser general public license'} = "GNU Lesser General Public License, Version Unspecified (LGPL)";
    $normalized_licenses{'lgpl'} = "GNU Lesser General Public License, Version Unspecified (LGPL)";
    
    # http://www.bearcave.com/software/java/xml/xmlpull_license.html
    # (An acknowledgement-only license)
    $normalized_licenses{'indiana university extreme! lab software license, vesion 1.1.1'} = "Indiana University Extreme! Lab Software License, Version 1.1.1";
    
    # HTML Tidy "uses a MIT-like license."
    # http://tidy.sourceforge.net/#license
    # http://tidy.cvs.sourceforge.net/tidy/tidy/include/tidy.h?view=markup
    # JTidy also uses this license:
    # http://jtidy.sourceforge.net/license.html
    $normalized_licenses{'java html tidy license'} = "Java HTML Tidy License (MIT-style License)";
    
    # http://opensource.org/licenses/MIT
    $normalized_licenses{'mit license'} = "MIT License";
    
    # http://opensource.org/licenses/MPL-2.0
    # Per http://opensource.org/licenses/MPL-1.1:
    # "[Version 1.1] has been superseded by the Mozilla Public License 2.0; please use the MPL 2.0 instead of 1.1."
    # Also: http://www.mozilla.org/MPL/2.0/Revision-FAQ.html
    $normalized_licenses{'mpl 1.1'} = "Mozilla Public License, Version 1.1 (MPL-1.1)";
    # Unspecified version(s)
    $normalized_licenses{'mozilla public license'} = "Mozilla Public License, Version Unspecified";
        
    # The concurrency packages developed by Doug Lea, et al., at SUNY Oswego
    # are in the public domain. Some modified OpenJDK Collections classes
    # use the GPL 2.1 with Classpath Exception license.
    # http://g.oswego.edu/dl/concurrency-interest/
    $normalized_licenses{'oswego'} = "Public Domain plus (for some parts) GNU General Public License, Version 2 (GPL-2.0) with Classpath Exception";

    $normalized_licenses{'public domain'} = "Public Domain";

    # http://terracotta.org/legal/terracotta-public-license
    # and http://terracotta.org/legal/licensing-overview
    $normalized_licenses{'terracotta public license'} = "Terracotta Public License (version 1.0)";
    
    # http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
    $normalized_licenses{'the w3c software license'} = "W3C Software License";

    # Spelling of 'unamed' is original
    $normalized_licenses{'unamed'} = "unknown"; # JPA 2.0 API, in Application layer dependencies
    
    return %normalized_licenses;
}

sub print_usage {
    my $script_name = basename($0);
    print <<"END_USAGE_INSTRUCTIONS";
$script_name:
Provides a concise summary of licensing information
for a project. Requires that you first run
'mvn project-info-reports:dependencies' (or an
equivalent Ant task which runs that Maven report).

Usages:

$script_name [--html|--text] [options] (default values in parens)
Required argument (choose only one):
--html Generate HTML output to the console
or
--text Generate text output to the console
Options:
--no-normalize Disable normalization of license names (enabled by default)
--separator [separator string] Separator to use with text output ($default_separator)

END_USAGE_INSTRUCTIONS
    exit(0);
}



