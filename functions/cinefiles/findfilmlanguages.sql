-- return concatenated string of film languages, taking filmId shortidentifier as input
-- used in CineFiles denorm process
-- CRH 2/22/2014

create or replace function cinefiles_denorm.findfilmlanguages(text)
returns text
as
$$
declare
   langstring text;
   r text;

begin

langstring := '';

FOR r IN
SELECT cinefiles_denorm.getdispl(wcl.item) filmLanguage
FROM works_common wc
LEFT OUTER JOIN works_cinefiles_languages wcl
   ON ( wc.id = wcl.id)
WHERE wc.shortidentifier = $1
ORDER BY wcl.pos
LOOP

langstring := langstring || r || '|';

END LOOP;

if langstring = '|' then langstring = null;
end if;

langstring := trim(trailing '|' from langstring);

return langstring;
end;
$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;