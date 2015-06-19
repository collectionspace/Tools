 CREATE OR REPLACE FUNCTION utils.concat_artists_fml(csid character varying)
  RETURNS character varying
  LANGUAGE plpgsql
  IMMUTABLE STRICT
 AS $function$
 
 DECLARE artiststring VARCHAR(300);
 
 BEGIN
 
 select array_to_string(
     array_agg(
         ptg.termname
         order by hoppg.pos),
         '; ')
 into artiststring
 from collectionobjects_common coc
 left outer join hierarchy hcoc on (
     coc.id = hcoc.id)
 left outer join hierarchy hoppg on (
     coc.id = hoppg.parentid
     and hoppg.primarytype = 'bampfaObjectProductionPersonGroup')
 left outer join bampfaobjectproductionpersongroup oppg on (
     hoppg.id = oppg.id)
 left outer join persons_common pc on (
     oppg.bampfaobjectproductionperson = pc.refname)
 left outer join hierarchy hptg on (
     pc.id = hptg.parentid
     and hptg.primarytype = 'personTermGroup'
     and hptg.pos = 0)
 left outer join persontermgroup ptg on (
     hptg.id = ptg.id)
 where hcoc.name = $1
 and oppg.bampfaobjectproductionperson is not null
 and oppg.bampfaobjectproductionperson != ''
 group by hcoc.name
 ;
 
 RETURN artiststring;
 
 END;
 
 $function$
