-- DROP FUNCTION utils.concat_artists (csid VARCHAR);

--Concatenates names of artists associated with a collection item in the standard 'lastnam, first middle' format.
 CREATE OR REPLACE FUNCTION utils.concat_artists(csid character varying)
  RETURNS character varying
  LANGUAGE plpgsql
  IMMUTABLE STRICT
 AS $function$
 
 DECLARE artiststring VARCHAR(300);
 
 BEGIN
 
 select array_to_string(
     array_agg(
         utils.getdispl(b.bampfaobjectproductionperson) ||
         case when b.bampfaobjectproductionpersonqualifier is not null
             and b.bampfaobjectproductionpersonqualifier != ''
             then ' (' || utils.getdispl(b.bampfaobjectproductionpersonqualifier) || ')'
             else ''
         end
         order by hb.pos),
         '; ')
     into artiststring
 from collectionobjects_common coc
 inner join hierarchy hcoc on (
     coc.id = hcoc.id)
 inner join hierarchy hb on (
     coc.id = hb.parentid
     and hb.name = 'collectionobjects_bampfa:bampfaObjectProductionPersonGroupList')
 inner join bampfaobjectproductionpersongroup b on (
     hb.id = b.id)
 where hcoc.name = $1
 and b.bampfaobjectproductionperson is not null
 and b.bampfaobjectproductionperson != ''
 group by hcoc.name
 ;
 
 RETURN artiststring;
 
 END;
 
 $function$
 
GRANT EXECUTE ON FUNCTION utils.concat_artists (csid VARCHAR) TO PUBLIC;

/*
select coc.objectnumber, utils.concat_artists(hcoc.name)
from collectionobjects_common coc
inner join hierarchy hcoc on (coc.id = hcoc.id)
where coc.objectnumber in (
    'EL.2.00.3',
    '1995.46.432.6',
    '2005.14.81',
    '1994.13.3');
 2005.14.81    | T.R. Uthco; Hall, Doug; Hall, Diane Andrews; Procter, Jody; Ant Farm; Lord, Chip; M
ichels, Doug; Schreier, Curtis
 1995.46.432.6 | ALPERT, Richard
 1994.13.3     | Alvarez, D-L; Black, Joan Jett; Blake, Nayland; Courtney, Erin; Ewert, Mary; Fectea
u, Vincent; Gonzales, Mark; Han, Donna; Hengst, Cliff; Horvitz, Philip; Johnson, David E.; Killian, 
Kevin; Lindell, John; Little, Connell Ray; Mayerson, Keith; Rollman, Michelle; Smith, Wayne; Winters
, Jim
 EL.2.00.3     | Galle, Philip; Bruegel, Pieter, I (After)
*/
