#
sub toSec {
	my ($h,$m,$s) = split /:/,@_[0];
	return $s + 60 * ($m + (60 * $h));
	return ($result < 0) ? $result + 86400 : $result;
}

my %stats;
my %dates;
my %apps;

open APPDATA,'webappuse.csv';
while (<APPDATA>) {
  chomp;
  s/ *\t */\t/g;
  my ($date,$ip,$app,$action,$end,$sec,$sys,$loc1,$loc2,$parms) = split "\t";
  next if $sys =~ /PROTOTYPE/;
  next if $app =~ / /;
  $app =~ s/'//g;
  $stats{$sys}{$app}{uses}++;
  $stats{$sys}{$app}{time}+=$sec;
  $date = substr($date,0,7);
  #print $date;
  $dates{$sys}{$date}{$app}++;
  $apps{$app}++;
}
print "<html>\n<a name=\"top\"/>\n<h1>Webapp Utilization Report</h1>\n<table border=\"1\">";
print "\n<h3>last updated: " . scalar localtime() . "</h3>\n";
foreach my $sys (sort keys %stats) {
  print "\n<h2>CSpace Database/Instance: $sys</h2>\n";
  print "\n<h3>Overall Use</h3>\n";
  print "\n<table border=\"1\" cellpadding=\"4px\">\n";
  my @header = ('app','uses','response time (s.)','average (s.)');
  print '<tr><th>' . join('<th>',@header) . '</tr>' . "\n";
  my %usage = %{ $stats{$sys} };
  my %myapps;
  foreach my $app (sort keys %usage) {
    $myapps{$app}++;
    my $appuses = $usage{$app}{uses};
    my $avgtime = $appuses > 0 ? $usage{$app}{'time'}/$appuses : 0;
    printf "<tr><td>%s</td><td>%s</td><td>%.1f</td><td>%.1f</td>\n",$app,$usage{$app}{uses},$usage{$app}{time},$avgtime; 
  }
  print "</table>\n";
  
  print "\n<h3>Daily Use</h3>\n";
  print "\n<table border=\"1\" cellpadding=\"4px\">\n";
  print '<tr><th>date<th>' . join('<th>',sort keys %myapps) . '</tr>' . "\n";
  my %sysdates = %{ $dates{$sys} };
  foreach my $date (sort keys %sysdates) {
    printf "<tr><td>%s</td>",$date;
    foreach my $app (sort keys %myapps) {
      printf "<td>%s</td>",$sysdates{$date}{$app};
    }
    print "</tr>\n";
  }
  print "</table>\n";
}

print "<hr><h5>Written by jblowe\@berkeley.edu on 20 Feb 2012.</h5>";
print "</html>\n";
exit(0);
my $reports;
print "</table>\n";
print "<hr><h2>Details</h2><hr>";
print $reports;
print "</html>\n";
