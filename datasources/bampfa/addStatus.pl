$runtype = @ARGV[0];
$location_column = @ARGV[1];
$crate_column = @ARGV[2];
while (<STDIN>) {
    @cell = split /\|/;
    $location = $cell[$location_column];
    # BAMPFA-412
    # "Asian Study"* => "located in Asian Study Center"
    # "Study Center*" => "located in Art Study Centers"
    # Ditto for "Gallery*", "Reading Room*", "Community Gallery*" = "On view"
    # Everything else is "Not on view"
    #
    # ok, ok, yes there is an implied if-then-else hidden here...I think it's fine, at least for now.
    $status = "Not on view";
    $status = "On View" if $location =~ /Gallery/i;
    $status = "On View" if $location =~ /Oxford, Lobby/i;
    $status = "located in Asian Study Center" if $location =~ /Asian Study/i;
    $status = "located in Art Study Center" if $location =~ /^Study\b/i;
    $i++;
    if $i == 1 {
        $status = "status";
    }
    else {
        if $runtype eq 'public' {
            @cell[$crate_column] = '-REDACTED-';
            @cell[$location_column] = '-REDACTED-';
        }
    }
    $_ = join(@cell,'|');
    # add to tail end of record.
    s/$/\|$status/;
    print;
}
