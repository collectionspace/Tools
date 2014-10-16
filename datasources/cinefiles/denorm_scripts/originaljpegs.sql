-- originaljpegs table used in CineFiles denorm for image harvesting
--
-- this script creates a temporary table, which will be renamed
-- after all of the denorm tables have been successfully created.
--
-- Modified GLJ 10/22/2014

DROP TABLE IF EXISTS cinefiles_denorm.originaljpegs;

CREATE TABLE cinefiles_denorm.originaljpegs AS
   WITH originaljpegs_view AS (
      SELECT h3.name csid, c.data md5, c.name contentname,
            replace(c.name, 'OriginalJpeg_', '') filename,
            regexp_split_to_array(c.name, '[_.]') nameparts,
            cc.updatedat updatedat
      FROM content c
        INNER JOIN hierarchy h1
              ON (c.id = h1.id AND h1.primarytype = 'content')
        INNER JOIN view v
              ON (h1.parentid = v.id AND v.title = 'OriginalJpeg')
        INNER JOIN hierarchy h2
              ON (v.id = h2.id AND h2.primarytype = 'view')
        INNER JOIN picture p
              ON (p.id = h2.parentid)
        INNER JOIN blobs_common b
              ON (b.repositoryid = p.id AND b.mimetype = 'image/tiff')
        INNER JOIN hierarchy h3
              ON (h3.id = b.id AND h3.primarytype = 'Blob')
        INNER JOIN collectionspace_core cc
              ON (b.id = cc.id)
        INNER JOIN misc m
              ON (h3.id = m.id AND m.lifecyclestate <> 'deleted')
   )
   SELECT csid,
          md5,
          contentname, 
          nameparts[2] as document_id,
          nameparts[2]||'.'||nameparts[3]||'.'||nameparts[5] as filename,
          updatedat
   FROM originaljpegs_view;

GRANT SELECT on cinefiles_denorm.originaljpegs to GROUP reporters;
GRANT SELECT on cinefiles_denorm.originaljpegs to GROUP cinereaders;

CREATE INDEX origjpegfilename_idx ON cinefiles_denorm.originaljpegs(filename);
CREATE INDEX origjpegcsid_idx ON cinefiles_denorm.originaljpegs(csid);
CREATE INDEX origjpegdocid_idx ON cinefiles_denorm.originaljpegs(document_id);

