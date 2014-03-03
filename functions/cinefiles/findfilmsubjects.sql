-- return concatenated string of film subjects, taking filmId shortidentifier as input
-- used in CineFiles denorm process
-- CRH 2/22/2014

create or replace function cinefiles_denorm.findfilmsubjects(text)
returns text
as
$$
declare
   subjectstring text;
   r text;

begin

subjectstring := '';

FOR r IN
SELECT cinefiles_denorm.getdispl(wcs.item) filmSubject
FROM works_common wc
LEFT OUTER JOIN works_cinefiles_subjects wcs ON ( wc.id = wcs.id)
WHERE wc.shortidentifier = $1
ORDER BY wcs.pos

LOOP

subjectstring := subjectstring || r || '|';

END LOOP;

if subjectstring = '|' then subjectstring = null;
end if;

subjectstring := trim(trailing '|' from subjectstring);

return subjectstring;
end;
$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;