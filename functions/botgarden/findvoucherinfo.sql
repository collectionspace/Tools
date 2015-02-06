-- findvoucherinfo.sql
-- return concatenated string of voucher information, taking accession CSID as input
-- used in Bot Garden portal
-- CRH 1/30/2015

create or replace function utils.findvoucherinfo(text)
returns text
as
$$

select
  array_to_string(array_agg(concat_ws(', ', regexp_replace(lc.borrower, '^.*\)''(.*)''$', '\1'), to_char(lc.loanoutdate, 'YYYY-MM-DD'))), '|') as voucherinfo
from relations_common rv 
join hierarchy hv on (rv.objectcsid=hv.name and rv.subjectcsid = $1 and rv.objectdocumenttype='Loanout')
join loansout_common lc on (lc.id=hv.id)
join misc mv on (lc.id=mv.id and mv.lifecyclestate <> 'deleted');

$$
LANGUAGE 'sql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;