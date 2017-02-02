/* UCJEPS-657:
   2017/01/09 LKV: function creates a display date for the Collector Labels Report, specifically for the John Muir specimens,
   where the accession numbers begin with the prefix 'JOMU').  This is necessary because the scalar dateearliestscalarvalue
   and datelatestscalarvalue are not populated for these records.  Requested format is 'YYYY/MM/DD' and 'YYYY/MM/DD - YYYY/MM/DD'
   for date ranges.  Some dates have no month or day values, and these parts are omitted when null, e.g. '1867/06'.
*/

CREATE OR REPLACE FUNCTION utils.get_fieldcolldate_range (cocid VARCHAR)
RETURNS VARCHAR
AS
$$

DECLARE
        eyear INTEGER;
        emonth INTEGER;
        eday INTEGER;
        lyear INTEGER;
        lmonth INTEGER;
        lday INTEGER;
        edate VARCHAR(100);
        ldate VARCHAR(100);
        datestring VARCHAR(200);

BEGIN

select
        sdg.dateearliestsingleyear,
        sdg.dateearliestsinglemonth,
        sdg.dateearliestsingleday,
        sdg.datelatestyear,
        sdg.datelatestmonth,
        sdg.datelatestday
into
        eyear,
        emonth,
        eday,
        lyear,
        lmonth,
        lday
from collectionobjects_common coc
left outer join hierarchy hsdg on (
        coc.id = hsdg.parentid and
        name = 'collectionobjects_common:fieldCollectionDateGroup')
left outer join structureddategroup sdg on (hsdg.id = sdg.id)
where coc.id = $1;


if eyear is not null and emonth is not null and eday is not null
        and lyear is not null and lmonth is not null and lday is not null
then
        select
                to_char(make_date(eyear, emonth, eday), 'YYYY/MM/DD'),
                to_char(make_date(lyear, lmonth, lday), 'YYYY/MM/DD')
        into
                edate,
                ldate;
else
        select
                coalesce(eyear::text, '0000') || '/' ||
                        lpad(coalesce(emonth::text, '00'), 2, '0') || '/' ||
                        lpad(coalesce(eday::text, '00'), 2, '0'),
                coalesce(lyear::text, '0000') || '/' ||
                        lpad(coalesce(lmonth::text, '00'), 2, '0') || '/' ||
                        lpad(coalesce(lday::text, '00'), 2, '0')
        into
                edate,
                ldate;

        edate := regexp_replace(regexp_replace(edate, '/00', '', 'g'), '^0000', '');
        ldate := regexp_replace(regexp_replace(ldate, '/00', '', 'g'), '^0000', '');

end if;

datestring := edate || case when ldate is null or ldate = '' then '' else ' - ' || ldate end;

--RAISE NOTICE 'early: % % %', eyear, emonth, eday;
--RAISE NOTICE 'late: % % %', lyear, lmonth, lday;
--RAISE NOTICE 'edate: % ldate: % datestring: %', edate, ldate, datestring;

RETURN datestring;

END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION utils.get_fieldcolldate_range (cocid VARCHAR) TO PUBLIC;

/*
select coc.objectnumber, sdg.datedisplaydate, utils.get_fieldcolldate_range(coc.id)
from collectionobjects_common coc
left outer join hierarchy h on (coc.id = h.parentid)
join structureddategroup sdg on (h.id = sdg.id and name = 'collectionobjects_common:fieldCollectionDateGroup')
where objectnumber like 'JOMU762%';

 objectnumber | datedisplaydate | get_fieldcolldate_range 
--------------+-----------------+-------------------------
 JOMU7620     | 1867            | 1867
 JOMU7621     |                 | 
 JOMU7622     | June 67         | 1867/06
 JOMU7624     | Nov 1865        | 1865/11/01 - 1865/11/30
 JOMU7625     | Nov 1865        | 1865/11
 JOMU7626     | Nov 1865        | 1865/11
 JOMU7627     | Nov 1865        | 1865/11
 JOMU7628     |                 | 
 JOMU7629     | Nov 1865        | 1865/11
 JOMU7623     |                 | 
(10 rows)
*/
