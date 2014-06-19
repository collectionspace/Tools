-- return concatenated string of document languages, taking collection object objectNumber as input
-- used in CineFiles denorm process
-- CRH 2/28/2014

create or replace function cinefiles_denorm.finddoclanguages(text)
returns text
as
$$
declare
   doclangstring text;
   r text;

begin

doclangstring := '';

FOR r IN
SELECT cinefiles_denorm.getdispl(cdl.item) doclanguage
FROM collectionobjects_common co
LEFT OUTER JOIN collectionobjects_cinefiles_doclanguages cdl ON (co.id = cdl.id)
WHERE co.objectnumber = $1
ORDER BY cdl.pos

LOOP

doclangstring := doclangstring || r || '|';

END LOOP;

if doclangstring = '|' then doclangstring = null;
end if;

doclangstring := trim(trailing '|' from doclangstring);

return doclangstring;
end;
$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;