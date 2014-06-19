-- DROP FUNCTION concat_collectors (cocid VARCHAR);

CREATE OR REPLACE FUNCTION concat_collectors (cocid VARCHAR)
RETURNS VARCHAR
AS
$$

DECLARE collstring VARCHAR(300);

BEGIN

select array_to_string(array_agg(getdispl(cocfc.item)), '; ')
into collstring
from collectionobjects_common coc
inner join collectionobjects_common_fieldcollectors cocfc on (coc.id = cocfc.id)
where coc.id = $1
and cocfc.item is not null
and cocfc.item != ''
group by coc.id;

RETURN collstring;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION concat_collectors (cocid VARCHAR) TO PUBLIC;
