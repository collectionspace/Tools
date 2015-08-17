--
--
--

CREATE or REPLACE FUNCTION utils.createObjectPlaceTable() RETURNS VOID AS
$$
  DROP TABLE IF EXISTS utils.object_place_temp;
  SELECT DISTINCT * INTO utils.object_place_temp FROM utils.object_place_view;
  CREATE INDEX opt_placecsid_ndx ON utils.object_place_temp(placecsid);
$$
LANGUAGE SQL
