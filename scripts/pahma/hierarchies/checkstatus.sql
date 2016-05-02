select *, row_number() over() as r from utils.refresh_log order by r desc limit 18;
select 'utils.culture_hierarchy', count(*) from utils.culture_hierarchy ;
select 'utils.current_location_temp', count(*) from utils.current_location_temp ;
select 'utils.material_hierarchy', count(*) from utils.material_hierarchy ;
select 'utils.object_place_location', count(*) from utils.object_place_location ;
select 'utils.object_place_temp', count(*) from utils.object_place_temp ;
select 'utils.placename_hierarchy', count(*) from utils.placename_hierarchy ;
select 'utils.taxon_hierarchy', count(*) from utils.taxon_hierarchy ;
