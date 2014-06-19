SELECT DISTINCT cc.id, STRING_AGG(DISTINCT mpg.measuredpart 
        ||CASE WHEN (dim.dimension IS NOT NULL) THEN '—' ELSE '' END
        ||CASE WHEN (dim.dimension IS NOT NULL AND dim.dimension <>0) THEN dim.dimension ELSE '' END
        ||CASE WHEN (dim.dimension IS NOT NULL AND dim.dimension <>0 AND dim.value IS NOT NULL AND dim.value <>0) THEN ' ' ELSE '' END
        ||CASE WHEN (dim.dimension IS NOT NULL AND dim.dimension <>0 AND dim.value IS NOT NULL AND dim.value <>0) THEN dim.value END
        ||CASE WHEN (dim.dimension IS NOT NULL AND dim.dimension <>0 AND dim.measurementunit IS NOT NULL AND dim.measurementunit <>'') THEN ' (' || dim.measurementunit || ')' ELSE '' END, '␥') AS "objdimensions_ss"
FROM collectionobjects_common cc
JOIN hierarchy hdm ON (hdm.parentid=cc.id AND hdm.primarytype='measuredPartGroup')
JOIN measuredpartgroup mpg ON (mpg.id=hdm.id AND mpg.measuredpart <> 'digitalImage')
JOIN hierarchy hdm2 ON (mpg.id=hdm2.parentid AND hdm2.primarytype='dimensionSubGroup')
JOIN dimensionsubgroup dim ON (dim.id=hdm2.id AND dim.measurementunit <> 'pixels' AND dim.measurementunit <> 'bits')
GROUP BY cc.id