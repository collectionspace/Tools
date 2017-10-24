-- gets taxon author name using taxon_common.id and taxonauthorgroup.taxonauthortype
-- should probably update to account for the invalid case when there is > 1 author per taxonauthortype....

CREATE OR REPLACE FUNCTION public.gettaxonauthor(tcid CHARACTER VARYING, tatype CHARACTER VARYING DEFAULT 'author')
  RETURNS CHARACTER VARYING
  LANGUAGE plpgsql
  IMMUTABLE STRICT
AS $$

DECLARE
  authorname VARCHAR(300);

BEGIN
  SELECT getdispl(tag.taxonauthor) INTO authorname
  FROM taxonauthorgroup tag, hierarchy h, taxon_common tc
  WHERE tc.id = h.parentid
  AND h.id = tag.id
  AND h.primarytype = 'taxonAuthorGroup'
  AND tc.id = $1
  AND tag.taxonauthortype = $2;

  RETURN authorname;
END;
$$

/* example queries
select gettaxonauthor('f5ebd86e-6e5a-4d82-89c6-34359175e178');
select gettaxonauthor('f5ebd86e-6e5a-4d82-89c6-34359175e178', 'author');
select gettaxonauthor('f5ebd86e-6e5a-4d82-89c6-34359175e178', 'ascribed author');
select gettaxonauthor('f5ebd86e-6e5a-4d82-89c6-34359175e178', 'parenthetical author');
select gettaxonauthor('f5ebd86e-6e5a-4d82-89c6-34359175e178', 'parenthetical ascribed author');

*/
