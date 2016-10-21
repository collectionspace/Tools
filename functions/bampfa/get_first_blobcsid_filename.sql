CREATE OR REPLACE FUNCTION utils.get_first_blobcsid_filename (title VARCHAR, returnvar VARCHAR)
RETURNS VARCHAR
AS
$$

DECLARE
   blobcsid VARCHAR(50);
   filename VARCHAR(50);

BEGIN

select mc.blobcsid, mc.title
into blobcsid, filename
from collectionobjects_common co
   JOIN hierarchy hrel on (co.id = hrel.id)
   JOIN relations_common rimg on (
       hrel.name = rimg.objectcsid and rimg.subjectdocumenttype = 'Media')
   JOIN hierarchy hmc on (rimg.subjectcsid = hmc.name)
   JOIN media_common mc on (mc.id = hmc.id)
   JOIN misc m on (mc.id = m.id and m.lifecyclestate <> 'deleted')
   JOIN media_bampfa mb on (
        mc.id = mb.id and mb.imagenumber = '1' and mb.websitedisplaylevel != 'No public display')
where hrel.name = $1;

IF $2 = 'blobcsid' THEN
   RETURN blobcsid;
ELSIF $2 = 'filename' THEN
   RETURN filename;
ELSIF $2 = 'both' THEN
   RETURN blobcsid || '; ' || filename;
ELSE
   RAISE NOTICE 'Invalid option: "%". The choices are: "blobcsid", "filename" or "both".', $2;
END IF;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION utils.get_first_blobcsid_filename (title VARCHAR, returnvar VARCHAR) TO reader_bampfa;
GRANT EXECUTE ON FUNCTION utils.get_first_blobcsid_filename (title VARCHAR, returnvar VARCHAR) TO GROUP reporters_bampfa;

/* test query in dev:
select get_first_blobcsid_filename('f7fe16a5-0ec8-4749-b32f-89d6e219991e', 'blobcsid');
select get_first_blobcsid_filename('f7fe16a5-0ec8-4749-b32f-89d6e219991e', 'filename');
select get_first_blobcsid_filename('f7fe16a5-0ec8-4749-b32f-89d6e219991e', 'both');
*/
