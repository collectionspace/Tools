-- create in cinefiles_domain database

CREATE OR REPLACE FUNCTION concat_worktitles (filmid VARCHAR)
RETURNS VARCHAR
AS
$$

DECLARE
    titlestring VARCHAR(1000);
    originaltitle VARCHAR(500);
    englishtitle VARCHAR(500);
    originalcount INTEGER;
    englishcount INTEGER;
    errormsg VARCHAR(500);

BEGIN

select into originalcount count(*)
from works_common wc
inner join hierarchy hwc on (
    wc.id = hwc.parentid
    and hwc.primarytype = 'workTermGroup'
    and hwc.pos = 0)
inner join worktermgroup wtg on (hwc.id = wtg.id)
where wc.shortidentifier = $1;

select into englishcount count(*)
from works_common wc
inner join hierarchy hwc on (
    wc.id = hwc.parentid
    and hwc.primarytype = 'workTermGroup'
    and hwc.pos > 0)
inner join worktermgroup wtg on (
    hwc.id = wtg.id
    and wtg.termlanguage like '%''English''%')
where wc.shortidentifier = $1;

IF originalcount = 0 THEN
    return NULL;

ELSEIF originalcount > 1 THEN
    errormsg := 'There can be only one! But there are ' ||
        originalcount::text || ' preferred titles!';
    RAISE EXCEPTION '%', errormsg;

ELSEIF originalcount = 1 THEN
    select into originaltitle trim(wtg.termdisplayname)
    from works_common wc
    inner join hierarchy hwc on (
        wc.id = hwc.parentid
        and hwc.primarytype = 'workTermGroup'
        and hwc.pos = 0)
    inner join worktermgroup wtg on (hwc.id = wtg.id)
    where wc.shortidentifier = $1;

    IF englishcount = 0 THEN
        titlestring := originaltitle;
        RETURN titlestring;

    ELSEIF englishcount = 1 THEN
        select into englishtitle trim(wtg.termdisplayname)
        from works_common wc
        inner join hierarchy hwc on (
            wc.id = hwc.parentid
            and hwc.primarytype = 'workTermGroup'
            and hwc.pos > 0)
        inner join worktermgroup wtg on (
            hwc.id = wtg.id
            and wtg.termlanguage like '%''English''%')
        where wc.shortidentifier = $1;

        titlestring := originaltitle || ' (' || englishtitle || ')';
        RETURN titlestring;

    ELSEIF englishcount > 1 THEN
        errormsg := 'There can be only one! But there are ' ||
            englishcount::text || ' non-preferred English titles!';
        RAISE EXCEPTION '%', errormsg;

    ELSE
        errormsg := 'Unable to get a count of non-preferred English titles!';
        RAISE EXCEPTION '%', errormsg;
    END IF;

ELSE
    errormsg := 'Unable to get a count of preferred titles!';
    RAISE EXCEPTION '%', errormsg;
END IF;
   
RETURN NULL;
   
END;

$$
LANGUAGE 'plpgsql'
IMMUTABLE
RETURNS NULL ON NULL INPUT;

GRANT EXECUTE ON FUNCTION concat_worktitles (filmid VARCHAR) TO PUBLIC;
