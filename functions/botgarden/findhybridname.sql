--  used by reports to build a combined hybrid name from hybrid parents
-- CRH 1/15/2013
-- from findhybridnamehtml though this one is simpler; removing joins to get taxonterm fields

CREATE OR REPLACE FUNCTION findhybridname(character varying) RETURNS character varying AS
$$
DECLARE
    numtimes integer;
    htmlname text; 
    strresult text;
    femalename text;
    malename text;
    parentgender text;

BEGIN

htmlname := '';
strresult := '';

SELECT into numtimes count(*)
FROM
    public.taxonomicidentgroup tig
left outer join hierarchy hhyb on (hhyb.parentid=tig.id and hhyb.name='taxonomicIdentHybridParentGroupList')
left outer join taxonomicidenthybridparentgroup thpg on (hhyb.id=thpg.id)
where tig.id = $1;

if numtimes > 1 then

FOR htmlname IN SELECT
    regexp_replace(thpg.taxonomicidenthybridparent, '^.*\)''(.*)''$', '\1')
FROM
    public.taxonomicidentgroup tig
left outer join hierarchy hhyb on (hhyb.parentid=tig.id and hhyb.name='taxonomicIdentHybridParentGroupList')
left outer join taxonomicidenthybridparentgroup thpg on (hhyb.id=thpg.id)
where tig.id = $1
order by taxonomicidenthybridparentqualifier
LOOP
    strresult := strresult || htmlname || ' × ';
END LOOP;

strresult := trim (trailing ' × ' from strresult);

elsif numtimes = 1 then

SELECT into htmlname, parentgender 
   regexp_replace(thpg.taxonomicidenthybridparent, '^.*\)''(.*)''$', '\1'),   
   thpg.taxonomicidenthybridparentqualifier
FROM
    public.taxonomicidentgroup tig
left outer join hierarchy hhyb on (hhyb.parentid=tig.id and hhyb.name='taxonomicIdentHybridParentGroupList')
left outer join taxonomicidenthybridparentgroup thpg on (hhyb.id=thpg.id)
where tig.id = $1;

-- if parentqualifier = 'female' then print htmlname||' × '
    if parentgender = 'female' then
      strresult := htmlname||' ×';

-- if parentqualifier = 'male' then print ' × '||htmlname
    elsif parentgender = 'male' then
      strresult := '× '||htmlname;

    end if; 

elsif numtimes = 0 then
-- fail
strresult := 'no hybrid parents';

end if;

RETURN strresult;

END; 
$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

