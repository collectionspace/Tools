-- function to return formatted hybrid name

create or replace function findhybridaffinhtml (tigid varchar)
returns varchar
as
$$
declare
	taxon_refname varchar(300);
	taxon_name varchar(200);
	taxon_name_form varchar(300);
	is_hybrid boolean;
	aff_refname varchar(300);
	aff_name varchar(200);
	aff_name_form varchar(300);
	aff_genus varchar(100);
	fhp_name varchar(200);
	fhp_genus varchar(100);
	mhp_name varchar(200);
	mhp_genus varchar(100);
	mhp_rest varchar(200);
	return_name varchar(300);

begin

select into
	taxon_refname,
	taxon_name,
	is_hybrid,
	aff_refname,
	aff_name,
	aff_genus
	tig.taxon,
	regexp_replace(tig.taxon, '^.*\)''(.+)''$', '\1'),
	tig.hybridflag,
	tig.affinitytaxon,
	regexp_replace(tig.affinitytaxon, '^.*\)''(.+)''$', '\1'),
	regexp_replace(tig.affinitytaxon, '^.*\)''([^ ]+)( ?.*)''$', '\1')
from taxonomicidentgroup tig
where tig.id = $1;

if not found then
	return null;

elseif is_hybrid is false and aff_name is null then
	select into taxon_name_form ttg.termformatteddisplayname
	from taxonomicidentgroup tig
	inner join taxon_common tc on (tig.taxon = tc.refname)
	inner join hierarchy h on (tc.id = h.parentid
		and h.primarytype = 'taxonTermGroup')
	inner join taxontermgroup ttg on (h.id = ttg.id
		and taxon_name = ttg.termdisplayname)
	where ttg.termformatteddisplayname is not null
	and tig.id = $1;

	return taxon_name_form;

elseif is_hybrid is false and aff_name is not null then
	select into aff_name_form
		regexp_replace(ttg.termformatteddisplayname,
			'^(<i>[^ ]+)( ?)(.*</i>.*)$', '\1</i> aff.\2<i>\3')
	from taxonomicidentgroup tig
	inner join taxon_common tc on (tig.affinitytaxon = tc.refname)
	inner join hierarchy h on (tc.id = h.parentid
		and h.primarytype = 'taxonTermGroup')
	inner join taxontermgroup ttg on (h.id = ttg.id
		and aff_name = ttg.termdisplayname)
	where ttg.termformatteddisplayname is not null
	and tig.id = $1;

	return aff_name_form;

elseif is_hybrid is true then
	select into fhp_name, fhp_genus
		case when fhp.taxonomicidenthybridparent is null then ''
			else ttg.termformatteddisplayname
		end,
		case when fhp.taxonomicidenthybridparent is null then ''
			else regexp_replace(fhp.taxonomicidenthybridparent,
				'^.*\)''([^ ]+)( ?.*)''$', '\1')
		end
	from taxonomicidentgroup tig
	inner join hierarchy hfhp on (hfhp.parentid = tig.id
		and hfhp.name = 'taxonomicIdentHybridParentGroupList')
	inner join taxonomicidenthybridparentgroup fhp on (hfhp.id = fhp.id
		and fhp.taxonomicidenthybridparentqualifier = 'female')
	inner join taxon_common tc on (fhp.taxonomicidenthybridparent = tc.refname)
	inner join hierarchy h on (tc.id = h.parentid
		and h.primarytype = 'taxonTermGroup')
	inner join taxontermgroup ttg on (h.id = ttg.id
		and regexp_replace(fhp.taxonomicidenthybridparent,
			 '^.*\)''(.+)''$', '\1') = ttg.termdisplayname)
	where ttg.termformatteddisplayname is not null
	and tig.id = $1;

	select into mhp_name, mhp_genus, mhp_rest
		case when mhp.taxonomicidenthybridparent is null then ''
			else ttg.termformatteddisplayname
		end,
		case when mhp.taxonomicidenthybridparent is null then ''
			else regexp_replace(mhp.taxonomicidenthybridparent,
				'^.*\)''([^ ]+)( .*)''$', '\1')
		end,
		case when mhp.taxonomicidenthybridparent is null then ''
			else regexp_replace(ttg.termformatteddisplayname,
				'^[Xx×]? ?<i>[^ ]+( ?.*)$', '\1')
		end
	from taxonomicidentgroup tig
	inner join hierarchy hmhp on (hmhp.parentid = tig.id
		and hmhp.name = 'taxonomicIdentHybridParentGroupList')
	inner join taxonomicidenthybridparentgroup mhp on (hmhp.id = mhp.id
		and mhp.taxonomicidenthybridparentqualifier = 'male')
	inner join taxon_common tc on (mhp.taxonomicidenthybridparent = tc.refname)
	inner join hierarchy h on (tc.id = h.parentid
		and h.primarytype = 'taxonTermGroup')
	inner join taxontermgroup ttg on (h.id = ttg.id
		and regexp_replace(mhp.taxonomicidenthybridparent,
			 '^.*\)''(.+)''$', '\1') = ttg.termdisplayname)
	where ttg.termformatteddisplayname is not null
	and tig.id = $1;

	if aff_name is null then
		if fhp_genus = mhp_genus then
			return_name := trim(fhp_name || ' × ' ||
				'<i>' || substr(mhp_genus, 1, 1) || '.' || mhp_rest);
		else
			return_name := trim(fhp_name || ' × ' || mhp_name);
		end if;
	else
		if aff_genus = mhp_genus then
			return_name := trim(aff_name_form || ' × ' ||
				'<i>' || substr(mhp_genus, 1, 1) || '.' || mhp_rest);
		else
			return_name := trim(aff_name_form || ' × ' || mhp_name);
		end if;
	end if;

	if return_name = ' × ' then 
		return null;
	else
		return return_name;
	end if;

end if;

return null;

end;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

/*
select pg_get_functiondef(oid)
from pg_proc
where proname = 'findhybridaffinhtml';

-- drop function findhybridaffinhtml (tigid varchar);

-- hybridflag is false and affinitytaxon is null
select id, regexp_replace(taxon, '^.*\)''(.*)''$', '\1'),
	findhybridaffinname(id), findhybridaffinhtml(id)
from taxonomicidentgroup
where id = '7c829525-8eed-4e38-b733-f4625d095b10';

 7c829525-8eed-4e38-b733-f4625d095b10 
 Phlox speciosa Pursh subsp. nitida (Suksd.) Wherry 
 Phlox speciosa Pursh subsp. nitida (Suksd.) Wherry
 <i>Phlox speciosa</i> Pursh subsp. <i>nitida</i> (Suksd.) Wherry

-- hybridflag is false and affinitytaxon is not null
select id, regexp_replace(taxon, '^.*\)''(.*)''$', '\1'),
	regexp_replace(affinitytaxon, '^.*\)''(.*)''$', '\1'),
	findhybridaffinname(id), findhybridaffinhtml(id)
from taxonomicidentgroup 
where id = 'ac990d00-e3ca-4986-b185-4504b2850513';

 ac990d00-e3ca-4986-b185-4504b2850513 
 Clematis	   
 Clematis japonica Thunb. 
 Clematis aff. japonica Thunb. 
 <i>Clematis</i> aff. <i>japonica</i> Thunb.

-- hybridflag is true and affinitytaxon is null
select id, regexp_replace(taxon, '^.*\)''(.*)''$', '\1'),
	findhybridaffinname(id), findhybridaffinhtml(id) 
from taxonomicidentgroup 
where id = '087f4b05-10c6-4a77-a86c-4325ac832b42';

 087f4b05-10c6-4a77-a86c-4325ac832b42 
 Trillium	   
 Trillium chloropetalum (Torr.) Howell Ã— T. ovatum Pursh 
 <i>Trillium chloropetalum</i> (Torr.) Howell Ã— <i>T. ovatum</i> Pursh

-- hybridflag is true and affinitytaxon is not null
select id, regexp_replace(taxon, '^.*\)''(.*)''$', '\1'),
	regexp_replace(affinitytaxon, '^.*\)''(.*)''$', '\1'),
	findhybridaffinname(id), findhybridaffinhtml(id) 
from taxonomicidentgroup 
where id = '7f4f0aa5-8a86-4113-89db-2cc6524cd2bb';

 7f4f0aa5-8a86-4113-89db-2cc6524cd2bb 
 Ceanothus	  
 Ceanothus prostratus Benth. var. occidentalis McMinn 
 Ceanothus aff. prostratus Benth. var. occidentalis McMinn Ã— C. cuneatus (Hook.) Nutt. 
 <i>Ceanothus</i> aff. <i>prostratus</i> Benth. var. <i>occidentalis</i> McMinn Ã— <i>C. cuneatus</i> (Hook.) Nutt.

-- CRH test case
select id, regexp_replace(taxon, '^.*\)''(.*)''$', '\1'),
	findhybridaffinname(id), findhybridaffinhtml(id) 
from taxonomicidentgroup 
where id = '772f7ebc-9fdc-42a2-bace-ae35644945ec';

 772f7ebc-9fdc-42a2-bace-ae35644945ec 
 Phlox		  
 Phlox divaricata L. Ã— P. condensata (A. Gray) E.E. Nelson 
 <i>Phlox divaricata</i> L. Ã— <i>P. condensata</i> (A. Gray) E.E. Nelson
*/
