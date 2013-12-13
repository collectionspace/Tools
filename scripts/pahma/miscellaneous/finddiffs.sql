select 

h.name,
cc.objectnumber,
findcurrentlocation(h.name) locationviamovments,
regexp_replace(cc.computedcurrentlocation, '^.*\)''(.*)''$', '\1') computedcurrentlocation

from collectionobjects_common cc
join hierarchy h on (cc.id = h.id)
where regexp_replace(computedcurrentlocation, '^.*\)''(.*)''$', '\1') <> regexp_replace(findcurrentlocation(h.name),':.*','')
