-- finddocauthorids.sql, return concatenated string of author ids, taking collection object objectNumber as input
-- used in CineFiles denorm process
-- CRH 7/31/2014

create or replace function cinefiles_denorm.finddocauthorids(text)
returns text
as
$$
declare
   docauthorstring text;
   r text;

begin

docauthorstring := '';

FOR r IN
SELECT cinefiles_denorm.getshortid(oppg.objectproductionperson) docauthor
FROM collectionobjects_common co
LEFT OUTER JOIN hierarchy h2
   ON (h2.parentid = co.id AND h2.primarytype = 'objectProductionPersonGroup')
LEFT OUTER JOIN objectProductionPersonGroup oppg
   ON (h2.id = oppg.id)
WHERE co.objectnumber = $1
ORDER BY h2.pos

LOOP

docauthorstring := docauthorstring || r || '|';

END LOOP;

if docauthorstring = '|' then docauthorstring = null;
end if;

docauthorstring := trim(trailing '|' from docauthorstring);

return docauthorstring;
end;
$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;