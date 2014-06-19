SELECT DISTINCT cc.id, STRING_AGG(ins.inscriptioncontent, '␥') AS "objinscrtext_ss"
FROM collectionobjects_common cc
JOIN hierarchy hti ON (hti.parentid=cc.id AND hti.primarytype='textualInscriptionGroup')
JOIN textualinscriptiongroup ins ON (ins.id=hti.id)
WHERE ins.inscriptioncontent IS NOT NULL
GROUP BY cc.id