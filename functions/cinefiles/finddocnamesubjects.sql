-- return concatenated string of document name subjects, taking collection object objectNumber as input
-- used in CineFiles denorm process
-- CRH 3/2/2014

create or replace function cinefiles_denorm.finddocnamesubjects(text)
returns text
as
$$
declare
   docnamesubjectstring text;
   r text;

begin

docnamesubjectstring := '';

FOR r IN
SELECT cinefiles_denorm.getdispl(ccn.item) docnamesubject
FROM collectionobjects_common co
LEFT OUTER JOIN collectionobjects_cinefiles_namesubjects ccn
  ON (co.id = ccn.id)
WHERE co.objectnumber = $1
ORDER BY ccn.pos

LOOP

docnamesubjectstring := docnamesubjectstring || r || '|';

END LOOP;

if docnamesubjectstring = '|' then docnamesubjectstring = null;
end if;

docnamesubjectstring := trim(trailing '|' from docnamesubjectstring);

return docnamesubjectstring;
end;
$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;