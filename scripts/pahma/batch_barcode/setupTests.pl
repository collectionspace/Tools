use POSIX 'strftime'; 
$date = strftime '%Y-%m-%d', localtime; 
while (<testfiles/*>) {
  chomp; 
  $x = "cp $_"; 
  s/2015-MM-DD/$date/; 
  $x .= " /tmp/$_\n";
  print($x);
  system($x);
}
