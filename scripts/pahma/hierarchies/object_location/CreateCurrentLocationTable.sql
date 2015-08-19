--
--
--

CREATE or REPLACE FUNCTION utils.createCurrentLocationTable() RETURNS VOID AS
$$
  DROP TABLE IF EXISTS utils.current_location_temp;
  SELECT DISTINCT * INTO utils.current_location_temp FROM utils.current_location_view;
  CREATE INDEX clt_objcsid_ndx ON utils.current_location_temp( collectionobjectcsid);
$$
LANGUAGE SQL
