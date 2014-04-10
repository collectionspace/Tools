CREATE OR REPLACE FUNCTION cinefiles_denorm.concat_personname (shortid VARCHAR)
RETURNS VARCHAR
AS
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

select into
        lastname,
        restofname,
        birthdeath,
        cityname,
        statename,
        countryname
coalesce(ptg.surname, ''),
trim(coalesce(ptg.forename || ' ', '') ||
        trim(coalesce(ptg.middlename || ' ', '') || coalesce(ptg.nameadditions, ''))),
trim('-' from coalesce(sdgb.datedisplaydate, '') || '-' || coalesce(sdgd.datedisplaydate, '')),
coalesce(pcf.birthcity, ''),
coalesce(pcf.birthstate, ''),
coalesce(getdispl(pc.birthplace), '')
from persons_common pc
left outer join hierarchy hptg on (
        pc.id = hptg.parentid
        and hptg.primarytype = 'personTermGroup'
        and hptg.pos = 0)
left outer join persontermgroup ptg on (hptg.id = ptg.id)
left outer join hierarchy hsdgb on (
        pc.id = hsdgb.parentid
        and hsdgb.primarytype = 'structuredDateGroup'
        and hsdgb.name = 'persons_common:birthDateGroup')
left outer join hierarchy hsdgd on (
        pc.id = hsdgd.parentid
        and hsdgd.primarytype = 'structuredDateGroup'
        and hsdgd.name = 'persons_common:deathDateGroup')
left outer join structureddategroup sdgb on (hsdgb.id = sdgb.id)
left outer join structureddategroup sdgd on (hsdgd.id = sdgd.id)
left outer join persons_cinefiles pcf on (pc.id = pcf.id)
where pc.shortidentifier = $1;

if not found then
    return null;
elseif lastname = '' then
        errormsg := 'Error: no last name';
        raise exception '%', errormsg;
else
        namestring := lastname;
end if;

if restofname != '' then
        namestring := namestring || ', ' || restofname;
end if;

if birthdeath != '' then
        namestring := namestring || ' (' || birthdeath || ')';
end if;

if cityname != '' then
        namestring := namestring || ', ' || cityname;
end if;

if statename != '' then
        namestring := namestring || ', ' || statename;
end if;

if countryname != '' then
        namestring := namestring || ', ' || countryname;
end if;

return namestring;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION cinefiles_denorm.concat_personname (shortid VARCHAR) TO PUBLIC;
