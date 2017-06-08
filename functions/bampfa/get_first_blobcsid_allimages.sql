CREATE OR REPLACE FUNCTION utils.get_first_blobcsid_allimages (title VARCHAR)
RETURNS VARCHAR
AS
$$

DECLARE blobcsid VARCHAR(50);

BEGIN

select
   mc.blobcsid into blobcsid
from collectionobjects_common co
   JOIN hierarchy hrel on (co.id = hrel.id)
   JOIN relations_common rimg on (hrel.name = rimg.objectcsid and rimg.subjectdocumenttype = 'Media')
   JOIN hierarchy hmc on (rimg.subjectcsid = hmc.name)
   JOIN media_common mc on (mc.id = hmc.id)
   JOIN misc m on (mc.id = m.id and m.lifecyclestate <> 'deleted')
   JOIN media_bampfa mb on (mc.id = mb.id and mb.imagenumber = '1')
where hrel.name = $1;

RETURN blobcsid;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION utils.get_first_blobcsid_allimages (title VARCHAR) TO reader_bampfa;
GRANT EXECUTE ON FUNCTION utils.get_first_blobcsid_allimages (title VARCHAR) TO GROUP reporters_bampfa;
