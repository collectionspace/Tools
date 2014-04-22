CREATE OR REPLACE FUNCTION getdispl(text)
    RETURNS text
    LANGUAGE sql
    IMMUTABLE STRICT
AS $function$
    SELECT regexp_replace($1, '^.*\)''(.*)''$', '\1')
$function$
;

GRANT EXECUTE ON FUNCTION getdispl(text) to public;
