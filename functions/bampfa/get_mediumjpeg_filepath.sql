CREATE OR REPLACE FUNCTION utils.get_mediumjpeg_filepath (title VARCHAR)
RETURNS VARCHAR
AS
$$

DECLARE filepath VARCHAR(1000);

BEGIN

select
   '/home/app_bampfa/tomcat6-bampfa/nuxeo-server/data/bampfa_domain/data/'||substring(c.data, 1, 2)||'/'||substring(c.data, 3,2)||'/'||c.data
   into filepath
from collectionobjects_common co
   JOIN hierarchy hrel on (co.id = hrel.id)
   JOIN relations_common rimg on (hrel.name = rimg.objectcsid)
   JOIN hierarchy hmc on (rimg.subjectcsid = hmc.name)
   JOIN media_common mc on (mc.id=hmc.id)
   JOIN media_bampfa mb on (mc.id=mb.id and mb.imagenumber='1')
   JOIN hierarchy hblob ON (mc.blobcsid = hblob.name)
   JOIN blobs_common b on (hblob.id = b.id)
   JOIN picture p ON (b.repositoryid = p.id)
   JOIN hierarchy hv ON (p.id = hv.parentid)
   JOIN view v ON (hv.id = v.id AND v.tag='medium')
   JOIN hierarchy hcontent ON (v.id = hcontent.parentid)
   JOIN content c ON (hcontent.id = c.id)
where hrel.name=$1;

RETURN filepath;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION utils.get_mediumjpeg_filepath (title VARCHAR) TO PUBLIC;
