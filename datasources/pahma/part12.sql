SELECT cc.id, scd.datedisplaydate AS "objcolldate_s",
CASE
        WHEN scd.dateearliestsingleera = '' THEN DATE(scd.dateearliestscalarvalue)+1||'T19:00:00Z'
        WHEN scd.dateearliestsingleera = 'ce' THEN DATE(scd.dateearliestscalarvalue)+1||'T19:00:00Z'
        WHEN scd.dateearliestsingleera IS NULL THEN DATE(scd.dateearliestscalarvalue)+1||'T19:00:00Z'
        WHEN scd.dateearliestsingleera = 'bce' THEN '-'||DATE(scd.dateearliestscalarvalue)+1||'T19:00:00Z'
        WHEN scd.dateearliestsingleera = 'bp' AND DATE_PART('year', scd.dateearliestscalarvalue) <= 1950
                THEN CASE
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.dateearliestscalarvalue) AS text)) = 4
                                THEN (1950-DATE_PART('year', scd.dateearliestscalarvalue))||SUBSTRING(CAST(scd.dateearliestscalarvalue AS text),5,6)||'T19:00:00Z'
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.dateearliestscalarvalue) AS text)) = 3
                                THEN '0'||(1950-DATE_PART('year', scd.dateearliestscalarvalue))||SUBSTRING(CAST(scd.dateearliestscalarvalue AS text),5,6)||'T19:00:00Z'
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.dateearliestscalarvalue) AS text)) = 2
                                THEN '00'||(1950-DATE_PART('year', scd.dateearliestscalarvalue))||SUBSTRING(CAST(scd.dateearliestscalarvalue AS text),5,6)||'T19:00:00Z'
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.dateearliestscalarvalue) AS text)) = 1
                                THEN '000'||(1950-DATE_PART('year', scd.dateearliestscalarvalue))||SUBSTRING(CAST(scd.dateearliestscalarvalue AS text),5,6)||'T19:00:00Z'
                        ELSE (1950-DATE_PART('year', scd.dateearliestscalarvalue))||SUBSTRING(CAST(scd.dateearliestscalarvalue AS text),5,6)||'T19:00:00Z'
                END
        WHEN scd.dateearliestsingleera = 'bp' AND DATE_PART('year', scd.dateearliestscalarvalue) > 1950
                THEN CASE
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.dateearliestscalarvalue) AS text)) = 5
                                THEN (1950-DATE_PART('year', scd.dateearliestscalarvalue))||SUBSTRING(CAST(scd.dateearliestscalarvalue AS text),5,6)||'T19:00:00Z'
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.dateearliestscalarvalue) AS text)) = 4
                                THEN '-0'||ABS(1950-DATE_PART('year', scd.dateearliestscalarvalue))||SUBSTRING(CAST(scd.dateearliestscalarvalue AS text),5,6)||'T19:00:00Z'
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.dateearliestscalarvalue) AS text)) = 3
                                THEN '-00'||ABS(1950-DATE_PART('year', scd.dateearliestscalarvalue))||SUBSTRING(CAST(scd.dateearliestscalarvalue AS text),5,6)||'T19:00:00Z'
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.dateearliestscalarvalue) AS text)) = 2
                                THEN '-000'||ABS(1950-DATE_PART('year', scd.dateearliestscalarvalue))||SUBSTRING(CAST(scd.dateearliestscalarvalue AS text),5,6)||'T19:00:00Z'
                        ELSE '-'||(1950-DATE_PART('year', scd.dateearliestscalarvalue))||SUBSTRING(CAST(scd.dateearliestscalarvalue AS text),5,6)||'T19:00:00Z'
                END
        ELSE DATE(scd.dateearliestscalarvalue)||'T19:00:00Z'
        END AS "objcolldate_begin_dt",
CASE
        WHEN scd.datelatestera = '' THEN DATE(scd.datelatestscalarvalue)+1||'T19:00:00Z'
        WHEN scd.datelatestera = 'ce' THEN DATE(scd.datelatestscalarvalue)+1||'T19:00:00Z'
        WHEN scd.datelatestera IS NULL THEN DATE(scd.datelatestscalarvalue)+1||'T19:00:00Z'
        WHEN scd.datelatestera = 'bce' THEN '-'||DATE(scd.datelatestscalarvalue)+1||'T19:00:00Z'
        WHEN scd.datelatestera = 'bp' AND DATE_PART('year', scd.datelatestscalarvalue) <= 1950
                THEN CASE
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.datelatestscalarvalue) AS text)) = 4
                                THEN (1950-DATE_PART('year', scd.datelatestscalarvalue))||SUBSTRING(CAST(scd.datelatestscalarvalue AS text),5,6)||'T19:00:00Z'
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.datelatestscalarvalue) AS text)) = 3
                                THEN '0'||(1950-DATE_PART('year', scd.datelatestscalarvalue))||SUBSTRING(CAST(scd.datelatestscalarvalue AS text),5,6)||'T19:00:00Z'
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.datelatestscalarvalue) AS text)) = 2
                                THEN '00'||(1950-DATE_PART('year', scd.datelatestscalarvalue))||SUBSTRING(CAST(scd.datelatestscalarvalue AS text),5,6)||'T19:00:00Z'
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.datelatestscalarvalue) AS text)) = 1
                                THEN '000'||(1950-DATE_PART('year', scd.datelatestscalarvalue))||SUBSTRING(CAST(scd.datelatestscalarvalue AS text),5,6)||'T19:00:00Z'
                        ELSE (1950-DATE_PART('year', scd.datelatestscalarvalue))||SUBSTRING(CAST(scd.datelatestscalarvalue AS text),5,6)||'T19:00:00Z'
                END
        WHEN scd.datelatestera = 'bp' AND DATE_PART('year', scd.datelatestscalarvalue) > 1950
                THEN CASE
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.datelatestscalarvalue) AS text)) = 5
                                THEN (1950-DATE_PART('year', scd.datelatestscalarvalue))||SUBSTRING(CAST(scd.datelatestscalarvalue AS text),5,6)||'T19:00:00Z'
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.datelatestscalarvalue) AS text)) = 4
                                THEN '-0'||ABS(1950-DATE_PART('year', scd.datelatestscalarvalue))||SUBSTRING(CAST(scd.datelatestscalarvalue AS text),5,6)||'T19:00:00Z'
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.datelatestscalarvalue) AS text)) = 3
                                THEN '-00'||ABS(1950-DATE_PART('year', scd.datelatestscalarvalue))||SUBSTRING(CAST(scd.datelatestscalarvalue AS text),5,6)||'T19:00:00Z'
                        WHEN CHAR_LENGTH(CAST(1950-DATE_PART('year', scd.datelatestscalarvalue) AS text)) = 2
                                THEN '-000'||ABS(1950-DATE_PART('year', scd.datelatestscalarvalue))||SUBSTRING(CAST(scd.datelatestscalarvalue AS text),5,6)||'T19:00:00Z'
                        ELSE '-'||(1950-DATE_PART('year', scd.datelatestscalarvalue))||SUBSTRING(CAST(scd.datelatestscalarvalue AS text),5,6)||'T19:00:00Z'
                END
        ELSE DATE(scd.datelatestscalarvalue)||'T19:00:00Z'
        END AS "objcolldate_end_dt"
FROM collectionobjects_common cc
JOIN hierarchy hcd ON (hcd.parentid=cc.id AND hcd.primarytype='structuredDateGroup' AND hcd.name='collectionobjects_pahma:pahmaFieldCollectionDateGroupList' AND (hcd.pos=0 or hcd.pos IS NULL))
JOIN structureddategroup scd ON (scd.id=hcd.id)
WHERE scd.datedisplaydate IS NOT NULL