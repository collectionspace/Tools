-- Reset vocabulary csids to known values. This script should be run after recreating a database, and initializing authorities.

-- Concept
update hierarchy set name='f53af507-2456-4faf-be53' where id = (select id from conceptauthorities_common where shortidentifier='activity');
update hierarchy set name='9de7a62f-595b-43f8-a795' where id = (select id from conceptauthorities_common where shortidentifier='ethusecode');
update hierarchy set name='53d6c048-89a2-4fe3-a8d7' where id = (select id from conceptauthorities_common where shortidentifier='archculture');
update hierarchy set name='06917b20-1c61-4e11-a0d2' where id = (select id from conceptauthorities_common where shortidentifier='concept');
update hierarchy set name='660a70af-001a-49c2-96f2' where id = (select id from conceptauthorities_common where shortidentifier='material_ca');

-- Location
update hierarchy set name='815b2b2b-e0c7-43d3-9b6b' where id = (select id from locationauthorities_common where shortidentifier='offsite_sla');
update hierarchy set name='d65c614a-e70e-441b-8855' where id = (select id from locationauthorities_common where shortidentifier='location');
update hierarchy set name='e8069316-30bf-4cb9-b41d' where id = (select id from locationauthorities_common where shortidentifier='crate');

-- Organization
update hierarchy set name='bcc8a400-4c10-42de-aa5b' where id = (select id from orgauthorities_common where shortidentifier='ulan_oa');
update hierarchy set name='253147a6-73b8-4561-a1c7' where id = (select id from orgauthorities_common where shortidentifier='organization');

-- Person
update hierarchy set name='32494f8b-5c18-427a-b237' where id = (select id from personauthorities_common where shortidentifier='person');
update hierarchy set name='a106839d-97bf-4e26-be6e' where id = (select id from personauthorities_common where shortidentifier='ulan_pa');

-- Place
update hierarchy set name='b5ac9f31-eeb1-490f-b57f' where id = (select id from placeauthorities_common where shortidentifier='place');
update hierarchy set name='00a331ad-f7ef-4fb0-920f' where id = (select id from placeauthorities_common where shortidentifier='tgn_place');

-- Taxon
update hierarchy set name='42e12057-959c-490c-9c55' where id = (select id from taxonomyauthority_common where shortidentifier='taxon');
update hierarchy set name='d4eb08fd-6524-4b0c-b0c6' where id = (select id from taxonomyauthority_common where shortidentifier='common_ta');
