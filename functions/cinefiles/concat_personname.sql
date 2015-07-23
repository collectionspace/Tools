-- concat_personname function used by Cinefiles denorm
--
-- this function creates a formated name string including lastname, firstname,
-- middlename and name additions, date of birth, city, state, and country
-- take a persons_common.shortid for it's only argument
--
-- Modified, GLJ 8/5/2014 to use a modified copy of personsnamegroup

CREATE OR REPLACE FUNCTION cinefiles_denorm.concat_personname (shortid VARCHAR)
RETURNS VARCHAR AS
$$
DECLARE
   namestring VARCHAR(1000);
   lastname varchar(100);
   restofname varchar(100);
   birthdeath varchar(100);
   cityname varchar(100);
   statename varchar(100);
   countryname varchar(100);
   errormsg varchar(500);
BEGIN
SELECT INTO
   lastname,
   restofname,
   birthdeath,
   cityname,
   statename,
   countryname
   coalesce(ptg.surname, ''),
   trim(coalesce(ptg.forename || ' ', '') ||
      trim(coalesce(ptg.middlename || ' ', '') ||
      coalesce(ptg.nameadditions, ''))),
   trim('-' from coalesce(sdgb.datedisplaydate, '') || '-' ||
      coalesce(sdgd.datedisplaydate, '')),
   coalesce(pcf.birthcity, ''),
   coalesce(pcf.birthstate, ''),
   coalesce(getdispl(pc.birthplace), '')
FROM persons_common pc
   LEFT OUTER JOIN hierarchy hptg ON (
        pc.id = hptg.parentid
        AND hptg.primarytype = 'personTermGroup'
        AND hptg.pos = 0)
   LEFT OUTER JOIN cinefiles_denorm.persontermgroup ptg ON (hptg.id = ptg.id)
   LEFT OUTER JOIN hierarchy hsdgb ON (
        pc.id = hsdgb.parentid
        AND hsdgb.primarytype = 'structuredDateGroup'
        AND hsdgb.name = 'persons_common:birthDateGroup')
   LEFT OUTER JOIN hierarchy hsdgd ON (
        pc.id = hsdgd.parentid
        AND hsdgd.primarytype = 'structuredDateGroup'
        AND hsdgd.name = 'persons_common:deathDateGroup')
   LEFT OUTER JOIN structureddategroup sdgb ON (hsdgb.id = sdgb.id)
   LEFT OUTER JOIN structureddategroup sdgd ON (hsdgd.id = sdgd.id)
   LEFT OUTER JOIN persons_cinefiles pcf ON (pc.id = pcf.id)
WHERE pc.shortidentifier = $1;

IF NOT FOUND THEN
   RETURN null;
ELSEIF lastname = '' THEN
   errormsg := 'Error: no last name';
   raise exception '%', errormsg;
ELSE
   namestring := lastname;
END IF;

IF restofname != '' THEN
   namestring := namestring || ', ' || restofname;
END IF;

IF birthdeath != '' THEN
   namestring := namestring || ' (' || birthdeath || ')';
END IF;

IF cityname != '' THEN
   namestring := namestring || ', ' || cityname;
END IF;

IF statename != '' THEN
   namestring := namestring || ', ' || statename;
END IF;

IF countryname != '' THEN
   namestring := namestring || ', ' || countryname;
END IF;

RETURN namestring;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION cinefiles_denorm.concat_personname (shortid VARCHAR) TO PUBLIC;
