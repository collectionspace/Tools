
$tag1 = 'ns2:collectionspace_core';
$tag2 = 'ns2:account_permission';


#@s = <>;
#print @s;
s/<$tag1.*?$tag1>//m;
s/<$tag2.*?$tag2>//m;
print $_;
