@cell = split /\|/;
$status = $cell[37];
$status = "Study Center" if $status =~ /Study Center/i;
$status = "Gallery"      if $status =~ /Gallery/i;
$status = "Not on view"  unless $status =~ /(Study Center|Gallery)/;
# for now, until locations are set, everything is 'not on view'
$status = "Not on view";
$i++;
$status = "status" if $i == 1;
s/$/\|$status/;
