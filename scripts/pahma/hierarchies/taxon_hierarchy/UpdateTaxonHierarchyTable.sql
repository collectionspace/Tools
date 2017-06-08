--
--
--

CREATE OR REPLACE FUNCTION utils.updateTaxonHierarchyTable() RETURNS bigint AS
$$
DECLARE
  ph text;
  ch text;
  nxt utils.taxon_hierarchy.nextcsid%TYPE;
  cnt int;
BEGIN
  ph := '';
  ch := '';
  nxt := 1;
  cnt := 1;

  WHILE cnt < 100 LOOP
    UPDATE utils.taxon_hierarchy p1
      SET nextcsid = NULL,
          csid_hierarchy = p2.csid_hierarchy || '|' || p1.taxoncsid,
          taxon_hierarchy = p2.taxon_hierarchy || '|' || p1.taxon
    FROM utils.taxon_hierarchy p2
    WHERE  p1.nextcsid IS NOT NULL
      AND  p1.nextcsid = p2.taxoncsid
      AND  p2.nextcsid IS NULL;

    IF FOUND THEN
      select into cnt cnt+1;
    ELSE
      EXIT;
    END IF;
  END LOOP;

  RETURN cnt;
END;
$$
LANGUAGE plpgsql
