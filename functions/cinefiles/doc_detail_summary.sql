CREATE OR REPLACE FUNCTION cinefiles_denorm.doc_detail_summary(text, documentRC refcursor, doctitleRC refcursor, authorsRC refcursor, sourceRC refcursor, doctypeRC refcursor, langRC refcursor, docsubjRC refcursor, docnamesubjRC refcursor, docfilmsubjRC refcursor, docurlRC refcursor)
RETURNS SETOF refcursor AS
$$
DECLARE

--2 2nd query section from sybase version.  query 1 not needed because just variables
BEGIN
open documentRC FOR
select 'Document' as Content, doc_id, pubdate as date, pages, code,
   case when pg_info is null then '' else pg_info end as pg_info,
   case when cast_cr = 'true' then 1 else 0 end as cast_cr,
   case when tech_cr = 'true' then 1 else 0 end as tech_cr,
   case when bx_info = 'true' then 1 else 0 end as bx_info,
   case when filmog = 'true' then 1 else 0 end as filmog,
   case when dist_co = 'true' then 1 else 0 end as dist_co,
   case when prod_co = 'true' then 1 else 0 end as prod_co,
   case when costinfo = 'true' then 1 else 0 end as cost,
   case when illust = 'true' then 1 else 0 end as illust,
   null as note
from cinefiles_denorm.doclist_view
where doc_id = $1;
RETURN NEXT documentRC;

-- 3
open doctitleRC FOR
select 'Document Title' as Content, doctitle as title
from cinefiles_denorm.doclist_view
where doc_id = $1;
RETURN NEXT doctitleRC;

--4
open authorsRC FOR
select 'Document Authors' as Content, name_id, 
case when author is null then '' else regexp_split_to_table(author, '[\|]+') end as author
from cinefiles_denorm.doclist_view
where doc_id = $1;
RETURN NEXT authorsRC;

--5
open sourceRC FOR
select 'Document Source' as Content, src_id, 
   case when source is null then '' else source end as source, 
   case when srcUrl is null then '' else srcUrl end as srcUrl
from cinefiles_denorm.doclist_view
where doc_id = $1;
RETURN NEXT sourceRC;

--6
open doctypeRC FOR
select 'Document Type' as Content, 
   case when dv.doctype is null then '' else dv.doctype end as type
from cinefiles_denorm.doclist_view dv
where doc_id = $1;
RETURN NEXT doctypeRC;

-- 7
open langRC FOR
select 'Document Languages' as Content, 
case when doclanguage is null then '' else regexp_split_to_table(doclanguage, '[\|]+') end as lang
from cinefiles_denorm.doclist_view
where doc_id = $1;
RETURN NEXT langRC;

--8
open docsubjRC FOR
select 'Document Subjects' as Content, 
case when docsubject is null then null else 2 end as subj_id, 
case when docsubject is null then '' else regexp_split_to_table(docsubject, '[\|]+') end as subj
from cinefiles_denorm.doclist_view
where doc_id = $1;
RETURN NEXT docsubjRC;

--9
open docnamesubjRC FOR
select 'Document Name Subjects' as Content, 2 as name_id, subjcitation namesubj
from cinefiles_denorm.docnamesubjectcitation
where doc_id = $1;
RETURN NEXT docnamesubjRC;

--10
open docfilmsubjRC FOR
select 'Document Film Subjects' as Content, fv.film_id,
   case when fv.filmtitle is null then '' else substring(concat(fv.filmtitle, ', ', split_part(fv.director, '|', 1), ', ', cast(fv.filmyear as text)), 1, 159) end as filmsubj
from cinefiles_denorm.doclist_view dv
left outer join cinefiles_denorm.filmdocs fd on (dv.doc_id=fd.doc_id)
left outer join cinefiles_denorm.filmlist_view fv on (fv.film_id=fd.film_id)
where dv.doc_id = $1;
RETURN NEXT docfilmsubjRC;

--11
open docurlRC FOR
select 'Document URL' as Content, 
   case when dv.docurl is null then '' else dv.docurl end as docurl
from cinefiles_denorm.doclist_view dv
where doc_id = $1;
RETURN NEXT docurlRC;

RETURN;
END;
$$
LANGUAGE 'plpgsql' STABLE
RETURNS NULL ON NULL INPUT;