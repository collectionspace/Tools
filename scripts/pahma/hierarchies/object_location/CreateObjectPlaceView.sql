--
--
--

CREATE or REPLACE FUNCTION utils.createObjectPlaceView() RETURNS VOID AS
$$
  CREATE OR REPLACE VIEW utils.object_place_view AS
  SELECT
      c.id,
      h1.name collectionobjectcsid,
      c.numberofobjects numberofobjects,
      c.objectnumber objectnumber,
      pn.placecsid placecsid
    FROM
      collectionobjects_common c
      JOIN misc m ON( m.id = c.id and m.lifecyclestate <> 'deleted' )
      JOIN hierarchy h1 ON( c.id = h1.id )
      JOIN collectionobjects_pahma_pahmafieldcollectionplacelist pl
        ON( pl.pos = 0 AND c.id = pl.id )
      JOIN places_common pc ON( pc.refname = pl.item )
      JOIN hierarchy h2 ON( h2.id = pc.id )
      JOIN utils.placename_hierarchy pn
        ON( h2.primarytype = 'PlaceitemTenant15'
            AND pn.placecsid = h2.name )
$$
LANGUAGE SQL
