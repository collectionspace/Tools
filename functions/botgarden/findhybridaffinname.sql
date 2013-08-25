-- function to get hybrid name

create or replace function findhybridaffinname (tigid varchar)
returns varchar
as
$$
declare
	taxon_name varchar(200);
	is_hybrid boolean;
	aff_name varchar(200);
	aff_genus varchar(100);
	fhp_name varchar(200);
	fhp_genus varchar(100);
	mhp_name varchar(200);
	mhp_genus varchar(100);
	mhp_rest varchar(200);
	return_name varchar(300);

begin

select into
	taxon_name,
	is_hybrid,
	aff_name,
	aff_genus
	regexp_replace(tig.taxon, '^.*\)''(.+)''$', '\1'),
	tig.hybridflag, 
	regexp_replace(tig.affinitytaxon, '^.*\)''([^ ]+)( ?.*)''$', '\1 aff.\2'),
	regexp_replace(tig.affinitytaxon, '^.*\)''([^ ]+)( ?.*)''$', '\1')
from taxonomicidentgroup tig
where tig.id = $1;

if not found then
	return null;

elseif is_hybrid is false and aff_name is null then
	return taxon_name;

elseif is_hybrid is false and aff_name is not null then
	return aff_name;

elseif is_hybrid is true then
	select into fhp_name, fhp_genus
		case when fhp.taxonomicidenthybridparent is null then ''
			else regexp_replace(fhp.taxonomicidenthybridparent,
				'^.*\)''(.+)''$', '\1')
		end,
		case when fhp.taxonomicidenthybridparent is null then ''
        	else regexp_replace(fhp.taxonomicidenthybridparent,
				'^.*\)''([^ ]+) ?.*''$', '\1')
		end
    from taxonomicidentgroup tig
    inner join hierarchy hfhp on (hfhp.parentid = tig.id 
		and hfhp.name = 'taxonomicIdentHybridParentGroupList')
    inner join taxonomicidenthybridparentgroup fhp on (hfhp.id = fhp.id 
		and fhp.taxonomicidenthybridparentqualifier = 'female')
    where tig.id = $1;

	select into mhp_name, mhp_genus, mhp_rest
		case when mhp.taxonomicidenthybridparent is null then ''
        	else regexp_replace(mhp.taxonomicidenthybridparent,
				'^.*\)''(.+)''$', '\1')
		end,
		case when mhp.taxonomicidenthybridparent is null then ''
        	else regexp_replace(mhp.taxonomicidenthybridparent,
				'^.*\)''([^ ]+) ?.*''$', '\1')
		end,
		case when mhp.taxonomicidenthybridparent is null then ''
        	else regexp_replace(mhp.taxonomicidenthybridparent,
				'^.*\)''([^ ]+)( ?.*)''$', '\2')
		end
    from taxonomicidentgroup tig
    inner join hierarchy hmhp on (hmhp.parentid = tig.id 
		and hmhp.name = 'taxonomicIdentHybridParentGroupList')
    inner join taxonomicidenthybridparentgroup mhp on (hmhp.id = mhp.id 
		and mhp.taxonomicidenthybridparentqualifier = 'male')
    where tig.id = $1;

	if aff_name is null then
		if fhp_genus = mhp_genus then
			return_name := trim(fhp_name || ' × ' || 
				substr(mhp_genus, 1, 1) || '.' || mhp_rest);
		else
			return_name := trim(fhp_name || ' × ' || mhp_name);
		end if;
	else 
		if aff_genus = mhp_genus then
			return_name := trim(aff_name || ' × ' || 
				substr(mhp_genus, 1, 1) || '.' || mhp_rest);
		else
			return_name := trim(aff_name || ' × ' || mhp_name);
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
