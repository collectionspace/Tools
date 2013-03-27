next unless /(Starting|records)/;
chomp;
s/^(\d+) .*?records 2012.*? /\1\t/;
s/^==.*run (.*?) PDT.*/\n\1\t/;
s/ (\d\d:\d\d:\d\d)/\t\1\t/;
s/ rel$//;
print ;
