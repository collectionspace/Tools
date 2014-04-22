-- DROP FUNCTION concat_comments (cocid VARCHAR);

CREATE OR REPLACE FUNCTION concat_comments (cocid VARCHAR)
RETURNS VARCHAR
AS
$$

DECLARE commstring VARCHAR(300);

BEGIN

select array_to_string(array_agg(getdispl(cocc.item)), '; ')
into commstring
from collectionobjects_common coc
inner join collectionobjects_common_comments cocc on (coc.id = cocc.id)
where coc.id = $1
and cocc.item is not null
and cocc.item != ''
group by coc.id;

RETURN commstring;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION concat_comments (cocid VARCHAR) TO PUBLIC;
