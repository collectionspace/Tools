-- findconserveorg.sql
-- return concatenated string of conservation organizations, taking taxon refname as input
-- used in Bot Garden portal
-- CRH 1/18/2015

create or replace function utils.findconserveorg(text)
returns text
as
$$
declare
   conserveorg text;
   r text;

begin

conserveorg := '';

FOR r IN
select 
   regexp_replace(pag.conservationorganization, '^.*\)''(.*)''$', '\1') as conserveorg
from taxon_common tc
left outer join hierarchy h
     on (tc.id = h.parentid and h.name = 'taxon_naturalhistory:plantAttributesGroupList')
left outer join plantattributesgroup pag on (pag.id=h.id)
where pag.conservationorganization is not null and pag.conservationorganization not like '%not applicable%'
     and tc.refname = $1
order by h.pos

LOOP

conserveorg := conserveorg || r || '|';

END LOOP;

if conserveorg = '|' then conserveorg = null;
end if;

conserveorg := trim(trailing '|' from conserveorg);

return conserveorg;
end;
$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;