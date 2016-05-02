--
--
-- CRH 12/6-11/2015 Refactored (e.g., create table as); corrected name of function; corrected field referenced in one index.

CREATE OR REPLACE FUNCTION utils.createObjectPlaceLocationTable() RETURNS VOID AS
$$
DROP TABLE IF EXISTS utils.object_place_location CASCADE;
CREATE TABLE utils.object_place_location AS
  SELECT
      o.id,
      l.collectionobjectcsid,
      o.objectnumber,
      o.numberofobjects,
      o.placecsid,
      p.placename,
      p.csid_hierarchy AS place_csid_hierarchy,
      l.storagelocation,
      l.crate
    FROM utils.object_place_temp o
      LEFT OUTER JOIN  utils.placename_hierarchy p
        ON (o.placecsid = p.placecsid)
      LEFT OUTER JOIN  utils.current_location_temp l
        ON (o.id = l.collectionobjectcsid);

  CREATE INDEX opn_id_ndx
  ON utils.object_place_location (id);
  CREATE INDEX opn_objnumber_ndx
  ON utils.object_place_location (objectnumber);
  CREATE INDEX opn_placename_ndx
  ON utils.object_place_location (placename);
  CREATE INDEX opn_csidhier_ndx
  ON utils.object_place_location (place_csid_hierarchy);
  CREATE INDEX opn_objcsid_ndx
  ON utils.object_place_location (collectionobjectcsid);
  CREATE INDEX opn_location_ndx
  ON utils.object_place_location (storagelocation);
$$
LANGUAGE SQL
