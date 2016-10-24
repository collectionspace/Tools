CREATE OR REPLACE FUNCTION utils.get_object_image_count(objcsid VARCHAR)
RETURNS VARCHAR
AS
$$

DECLARE
   imagecount INTEGER;

BEGIN

select count(*)
into imagecount
from collectionobjects_common co
   JOIN hierarchy hrel on (co.id = hrel.id)
   JOIN relations_common rimg on (
       hrel.name = rimg.objectcsid and rimg.subjectdocumenttype = 'Media')
   JOIN hierarchy hmc on (rimg.subjectcsid = hmc.name)
   JOIN media_common mc on (mc.id = hmc.id)
   JOIN misc m on (mc.id = m.id and m.lifecyclestate <> 'deleted')
where hrel.name = $1;

RETURN imagecount;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION utils.get_object_image_count(objcsid VARCHAR) TO reader_bampfa;
GRANT EXECUTE ON FUNCTION utils.get_object_image_count(objcsid VARCHAR) TO GROUP reporters_bampfa;

/* test queries for dev and prod:
select utils.get_object_image_count('f7fe16a5-0ec8-4749-b32f-89d6e219991e');
select utils.get_object_image_count('5f555913-aad3-4386-b743-06480cbbcee2');
*/
