-- DROP FUNCTION concat_localitynote (cocid VARCHAR);

CREATE OR REPLACE FUNCTION concat_localitynote (cocid VARCHAR)
RETURNS VARCHAR
AS
$$

DECLARE locstring VARCHAR(2000);

BEGIN

select
    case
        when lg.fieldloccounty is null and lg.fieldloccounty is null and lg.fieldloccountry is null
                then ''
        when lg.fieldloccounty is null or lg.fieldloccounty = '' or lg.fieldloccounty = ' ' then
            regexp_replace(
                regexp_replace(
                    coalesce(lg.fieldlocstate, '') || ', ' || coalesce(lg.fieldloccountry,''),
                    '^ ?, ', ''),
                ', *$', '') || '.'
        else
            regexp_replace(
                regexp_replace(
                    coalesce(lg.fieldloccounty, '') || ' County, ' ||
                        coalesce(lg.fieldlocstate, '') || ', ' || coalesce(lg.fieldloccountry,''),
                    ', +, ', ', '),
                ', *$', '') || '.'
    end ||
    case when lg.localitynote is null then '' else ' ' || lg.localitynote end ||
    case
        when lg.vlatitude is not null and lg.vlatitude != ''
                and lg.vlongitude is not null and lg.vlongitude != '' then
            ' ' || coalesce(lg.vlatitude, '') || ', ' || coalesce(lg.vlongitude, '')  || '.'
        when lg.vlatitude is null or lg.vlatitude = '' then
            ' ' || regexp_replace(coalesce(lg.vlongitude, '')  || '.',
                '^ *.$', '')
        when lg.vlongitude is null or lg.vlongitude = '' then
            ' ' || regexp_replace(coalesce(lg.vlatitude, '')  || '.',
                '^ *.$', '')
        else ''
    end  ||
    case
        when lg.vdepth is not null then ' ' || lg.vdepth || ' ' || coalesce(lg.depthunit, '')
            || ' depth'
        else ''
    end  ||
    case
        when lg.velevation is null then ''
        when lg.velevation ~ '^.*[a-z]$' then ' ' || lg.velevation || ' elev.'
        else ' ' || lg.velevation || ' ' || coalesce(lg.elevationunit, '') || ' elev.'
    end ||
    case when lg.localitysource is null then '' else ' Source: ' || lg.localitysource || '.' end
into locstring
from
collectionobjects_common coc
left outer join hierarchy hlg on (
    coc.id = hlg.parentid and hlg.primarytype = 'localityGroup' and hlg.pos = 0)
left outer join localityGroup lg on (hlg.id = lg.id)
where coc.id = $1;

RETURN locstring;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION concat_localitynote (cocid VARCHAR) TO PUBLIC;
