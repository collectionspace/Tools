--
--
--

CREATE or REPLACE FUNCTION utils.updateObjectPlaceLocation() RETURNS VOID AS
$$
DECLARE
BEGIN
  RAISE NOTICE 'Creating/Updating utils.current_location_temp';
  PERFORM utils.createCurrentLocationTable();

  RAISE NOTICE 'Populating utils.placename_hierarchy';
  PERFORM utils.populatePlacenameHierarchy();

  RAISE NOTICE 'Building hierarchies in utils.placename_hierarchy';
  PERFORM utils.updatePlacenameHierarchyTable();

  RAISE NOTICE 'Creating/updating utils.object_place_temp';
  PERFORM utils.createObjectPlaceTable();

  RAISE NOTICE 'Creating utils.object_place_location';
  PERFORM utils.createObjectPlaceLocation();
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE
