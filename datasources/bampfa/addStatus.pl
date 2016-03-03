@cell = split /\|/;
$status = $cell[37];
# BAMPFA-412
# "Asian Study"* => "located in Asian Study Center"
# "Study Center*" => "located in Art Study Centers"
# Ditto for "Gallery*", "Reading Room*", "Community Gallery*" = "On view"
# Everything else is "Not on view"
#
# ok, ok, yes there is an implied if-then-else hidden here...I think it's fine, at least for now.
$status = "Not on view";
$status = "located in Art Study Center" if $status =~ /Study Center/i;
$status = "located in Asian Study Center" if $status =~ /Asian Study/i;
$status = "On View" if $status =~ /(Gallery|Reading Room|Community Gallery)*/i;
$i++;
$status = "status" if $i == 1;
# add to tail end of record, vertical bar is delimiter here.
s/$/\|$status/;
