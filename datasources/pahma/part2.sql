SELECT DISTINCT
cc.id, STRING_AGG(DISTINCT ang.pahmaaltnum
                ||CASE WHEN (ang.pahmaaltnumtype IS NOT NULL OR ang.pahmaaltnumnote IS NOT NULL) THEN ' (' ELSE '' END
                ||CASE WHEN (ang.pahmaaltnumtype IS NOT NULL AND ang.pahmaaltnumtype <>'') THEN regexp_replace(ang.pahmaaltnum, '^.*\)''(.*)''$', '\1') ELSE '' END
                ||CASE WHEN (ang.pahmaaltnumtype IS NOT NULL AND ang.pahmaaltnumnote IS NOT NULL) THEN ', ' ELSE '' END
                ||CASE WHEN (ang.pahmaaltnumnote IS NOT NULL AND ang.pahmaaltnumnote <>'') THEN ang.pahmaaltnumnote ELSE '' END
                ||CASE WHEN (ang.pahmaaltnumtype IS NOT NULL OR ang.pahmaaltnumnote IS NOT NULL) THEN ')' ELSE '' END, '␥') AS "objaltnum_ss"
FROM collectionobjects_common cc
JOIN hierarchy han ON (han.parentid=cc.id AND han.primarytype='pahmaAltNumGroup')
JOIN pahmaaltnumgroup ang ON (ang.id=han.id)
WHERE ang.pahmaaltnum IS NOT NULL
GROUP BY cc.id
