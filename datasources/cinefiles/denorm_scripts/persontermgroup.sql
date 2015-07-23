DROP TABLE IF EXISTS cinefiles_denorm.persontermgroup;

SELECT * into cinefiles_denorm.persontermgroup from persontermgroup;

UPDATE cinefiles_denorm.persontermgroup
  SET surname = CASE
    WHEN array_upper((regexp_split_to_array(trim(termdisplayname), E'\\s+')), 1) > 0
    THEN
      (regexp_split_to_array(trim(termdisplayname), E'\\s+'))[
        array_upper((regexp_split_to_array(trim(termdisplayname), E'\\s+')), 1)]
    ELSE
      'Unknown'
  END,

  forename = CASE
    WHEN array_upper((regexp_split_to_array(trim(termdisplayname), E'\\s+')), 1) > 1
    THEN
      (regexp_split_to_array(trim(termdisplayname), E'\\s+'))[1]
    ELSE
      NULL
  END,

  middlename = CASE
    WHEN array_upper((regexp_split_to_array(trim(termdisplayname), E'\\s+')), 1) > 2
    THEN
      (regexp_split_to_array(trim(termdisplayname), E'\\s+'))[2]
    ELSE
      NULL
  END
WHERE length(coalesce(trim(surname), '')) = 0;

GRANT SELECT ON cinefiles_denorm.persontermgroup TO GROUP reporters;
GRANT SELECT ON cinefiles_denorm.persontermgroup TO GROUP cinereaders;

SELECT COUNT(1) FROM persontermgroup;
SELECT COUNT(1) FROM cinefiles_denorm.persontermgroup;

