SELECT DISTINCT cc.id,STRING_AGG((CASE WHEN dim.value = 0 OR dim.value IS NULL OR dim.measurementunit IS NULL THEN ''
WHEN mpg.measuredpart IS NULL AND dim.dimension IS NULL THEN dim.value || ' ' || dim.measurementunit
WHEN mpg.measuredpart IS NULL THEN dim.dimension || ' ' || dim.value || ' ' || dim.measurementunit
WHEN dim.dimension IS NULL THEN mpg.measuredpart || '— ' || dim.value || ' ' || dim.measurementunit
ELSE mpg.measuredpart || '— ' || dim.dimension || ' ' || dim.value || ' ' || dim.measurementunit
END), '␥') AS "objdimensions_ss"

FROM collectionobjects_common cc
JOIN hierarchy hdm ON (cc.id=hdm.parentid AND hdm.primarytype='measuredPartGroup')
JOIN measuredpartgroup mpg ON (mpg.id=hdm.id)
JOIN hierarchy hdm2 ON (mpg.id=hdm2.parentid AND hdm2.primarytype='dimensionSubGroup')
JOIN dimensionsubgroup dim ON (dim.id=hdm2.id AND dim.measurementunit <> 'pixels' AND dim.measurementunit <> 'bits')
GROUP BY cc.id