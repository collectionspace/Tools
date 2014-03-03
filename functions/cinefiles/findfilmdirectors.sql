-- return concatenated string of film directors, taking filmId shortidentifier as input
-- used in CineFiles denorm process
-- CRH 2/22/2014

create or replace function cinefiles_denorm.findfilmdirectors(text)
returns text
as
$$
declare
   directorstring text;
   r text;

begin

directorstring := '';

FOR r IN
SELECT cinefiles_denorm.getdispl(cg.creator) filmDirector
FROM hierarchy h1
INNER JOIN works_common wc
   ON ( h1.id = wc.id AND h1.primarytype = 'WorkitemTenant50' )
LEFT OUTER JOIN hierarchy h2
   ON ( h2.parentid = h1.id AND h2.primarytype = 'creatorGroup')
LEFT OUTER JOIN creatorgroup cg
   ON (h2.id = cg.id)
WHERE wc.shortidentifier = $1
ORDER BY h2.pos

LOOP

directorstring := directorstring || r || '|';

END LOOP;

if directorstring = '|' then directorstring = null;
end if;

directorstring := trim(trailing '|' from directorstring);

return directorstring;
end;
$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;