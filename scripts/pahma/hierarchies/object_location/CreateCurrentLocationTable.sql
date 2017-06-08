--
--
--

CREATE or REPLACE FUNCTION utils.createCurrentLocationTable() RETURNS VOID AS
$$
  DROP TABLE IF EXISTS utils.current_location_temp;
  SELECT DISTINCT *  INTO utils.current_location_temp FROM (
  SELECT
     cc.id AS collectionobjectcsid,
      REGEXP_REPLACE( cc.computedcurrentlocation, '^.*\)''(.*)''$', '\1' )
        AS storagelocation,
      (CASE when ca.computedcrate is NULL THEN
         NULL
      ELSE
        regexp_replace(ca.computedcrate, '^.*\)''(.*)''$', '\1') end) AS crate
    FROM
      collectionobjects_common cc
      left outer join collectionobjects_anthropology ca on (ca.id=cc.id)
      JOIN misc misc ON( cc.id = misc.id AND misc.lifecyclestate <> 'deleted' )
    ) AS current_location_subquery;

  CREATE INDEX clt_objcsid_ndx ON utils.current_location_temp( collectionobjectcsid);
$$
LANGUAGE SQL
