CREATE OR REPLACE FUNCTION cinefiles_denorm.getshortid(text)
   RETURNS text
   LANGUAGE sql
   IMMUTABLE STRICT
AS $function$
   SELECT regexp_replace($1, '^.*:item:name\(([^)]*)\).*$', '\1')
$function$;

GRANT EXECUTE ON FUNCTION cinefiles_denorm.getshortid(text) to public;

