--
--
--

CREATE OR REPLACE FUNCTION utils.updatePlacenameHierarchyTable() RETURNS bigint AS
$$
 DECLARE
   ph text;
   ch text;
   nxt utils.placename_hierarchy.nextcsid%TYPE;
   cnt int;
 BEGIN
   ph := '';
   ch := '';
   nxt := 1;
   cnt := 1;

   WHILE cnt < 100 LOOP
     UPDATE utils.placename_hierarchy p1
       SET nextcsid = NULL,
           csid_hierarchy = p2.csid_hierarchy || '|' || p1.placecsid,
           place_hierarchy = p2.place_hierarchy || '|' || p1.placename
     FROM utils.placename_hierarchy p2
     WHERE  p1.nextcsid IS NOT NULL
       AND  p1.nextcsid = p2.placecsid
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
