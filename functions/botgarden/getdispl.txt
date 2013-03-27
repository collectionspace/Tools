CREATE OR REPLACE FUNCTION getdispl(in text)
RETURNS text AS
$Q$
SELECT regexp_replace($1, '^.*\)''(.*)''$', '\1')
$Q$
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;
