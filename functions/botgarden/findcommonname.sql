CREATE OR REPLACE FUNCTION findcommonname(character varying) RETURNS character varying AS
$$
select regexp_replace(naturalhistorycommonname, '^.*\)''(.*)''$', '\1') commonname from taxon_common tc1
left outer join hierarchy hcn
     on (tc1.id = hcn.parentid and hcn.pos = 0 and hcn.name = 'taxon_naturalhistory:naturalHistoryCommonNameGroupList')
left outer join naturalhistorycommonnamegroup commonname on (commonname.id = hcn.id)
	-- and naturalhistorycommonnametype='preferred')
where tc1.refname=$1
$$ LANGUAGE SQL
    IMMUTABLE
    RETURNS NULL ON NULL INPUT;

