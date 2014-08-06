CREATE OR REPLACE FUNCTION cinefiles_denorm.getdispl(text)
    RETURNS text
    LANGUAGE sql
    IMMUTABLE STRICT
AS $function$
    SELECT regexp_replace($1, '^.*\)''(.*)''$', '\1')
$function$;

GRANT EXECUTE ON FUNCTION cinefiles_denorm.getdispl(text) to public;
