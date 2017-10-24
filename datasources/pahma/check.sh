time perl -ne '$x = $_ ;s/[^\t]//g; { print 1+length($_) . "\n";} '  $1 | sort | uniq -c
