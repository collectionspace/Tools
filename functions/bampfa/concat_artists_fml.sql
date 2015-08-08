-- DROP FUNCTION utils.concat_artists_fml (csid VARCHAR);

-- Concatenates names of artists associated with a collection object in 'first middle lastname' format.
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

GRANT EXECUTE ON FUNCTION utils.concat_artists_fml (csid VARCHAR) TO PUBLIC;

/*
select coc.objectnumber, utils.concat_artists_fml(hcoc.name)
from collectionobjects_common coc
inner join hierarchy hcoc on (coc.id = hcoc.id)
where coc.objectnumber in (
    'EL.2.00.3',
    '1995.46.432.6',
    '2005.14.81',
    '1994.13.3',
    '1995.46.184');
    
 2005.14.81    | T.R. Uthco; Doug Hall; Diane Andrews Hall; Jody Procter; Ant Farm; Chip Lord; Doug 
Michels; Curtis Schreier
 1995.46.432.6 | 
 1995.46.184   | Nova Scotia College of Art and Design; Iain Baxter; Eleanor Beveridge; Gerald Fergu
son; Hisako Hamada; George Kokis; Alyce Orehover; Paul Hrusovsky; Robert DeGaetano; Joseph Kosuth; J
im Leedy; Jim Melchert; P. Rada; Peter Voulkos; Mary B. Yates
 1994.13.3     | D-L Alvarez; Joan Jett Black; Nayland Blake; Erin Courtney; Mary Ewert; Vincent Fec
teau; Mark Gonzales; Donna Han; Cliff Hengst; Philip Horvitz; David E. Johnson; Kevin Killian; John 
Lindell; Connell Ray Little; Keith Mayerson; Michelle Rollman; Wayne Smith; Jim Winters
 EL.2.00.3     | Philip Galle; Pieter Bruegel I
*/
