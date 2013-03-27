--  used by voucher label report to build an HTML name from hybrid parents
-- CRH 12/31/2012

CREATE OR REPLACE FUNCTION findhybridnamehtml(character varying) RETURNS character varying AS
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
left outer join taxon_common tc on (thpg.taxonomicidenthybridparent=tc.refname)
left outer join hierarchy htt 
    on (tc.id=htt.parentid and htt.name='taxon_common:taxonTermGroupList' and htt.pos=0) -- for now assuming preferred name
left outer join taxontermgroup tt on (tt.id=htt.id)
where tig.id = $1;

if numtimes > 1 then

FOR htmlname IN SELECT
    tt.termformatteddisplayname
FROM
    public.taxonomicidentgroup tig
left outer join hierarchy hhyb on (hhyb.parentid=tig.id and hhyb.name='taxonomicIdentHybridParentGroupList')
left outer join taxonomicidenthybridparentgroup thpg on (hhyb.id=thpg.id)
left outer join taxon_common tc on (thpg.taxonomicidenthybridparent=tc.refname)
left outer join hierarchy htt 
    on (tc.id=htt.parentid and htt.name='taxon_common:taxonTermGroupList' and htt.pos=0)
left outer join taxontermgroup tt on (tt.id=htt.id)
where tig.id = $1
order by taxonomicidenthybridparentqualifier
LOOP
    strresult := strresult || htmlname || ' × ';
END LOOP;

strresult := trim (trailing ' × ' from strresult);

elsif numtimes = 1 then

SELECT into htmlname, parentgender 
tt.termformatteddisplayname, thpg.taxonomicidenthybridparentqualifier
FROM
    public.taxonomicidentgroup tig
left outer join hierarchy hhyb on (hhyb.parentid=tig.id and hhyb.name='taxonomicIdentHybridParentGroupList')
left outer join taxonomicidenthybridparentgroup thpg on (hhyb.id=thpg.id)
left outer join taxon_common tc on (thpg.taxonomicidenthybridparent=tc.refname)
left outer join hierarchy htt 
    on (tc.id=htt.parentid and htt.name='taxon_common:taxonTermGroupList' and htt.pos=0)
left outer join taxontermgroup tt on (tt.id=htt.id)
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

