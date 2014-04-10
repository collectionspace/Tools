-- DROP FUNCTION concat_othernumber (cocid VARCHAR);

CREATE OR REPLACE FUNCTION concat_othernumber (cocid VARCHAR)
RETURNS VARCHAR
AS
$$

DECLARE othernumstring VARCHAR(300);

BEGIN

select array_to_string(
    array_agg(coalesce(o.numbertype, 'NULL Number Type') || ':' || o.numbervalue),
    '; ')
into othernumstring
from collectionobjects_common coc
inner join hierarchy h on (coc.id = h.parentid and h.primarytype = 'otherNumber')
inner join othernumber o on (h.id = o.id)
where coc.id = $1
and o.numbervalue is not null
and o.numbervalue != ''
group by coc.id;

RETURN othernumstring;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION concat_othernumber (cocid VARCHAR) TO PUBLIC;
