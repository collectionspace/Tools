-- Reset vocabulary csids to known values. This script should be run after recreating a database, and initializing authorities.

-- Concept
update hierarchy set name='96141839-4bac-4e3d-a511' where id = (select id from conceptauthorities_common where shortidentifier='class_ca');
update hierarchy set name='bbe39bb2-a622-4570-a946' where id = (select id from conceptauthorities_common where shortidentifier='concept');
update hierarchy set name='241d7dac-8c74-420a-85f3' where id = (select id from conceptauthorities_common where shortidentifier='conservation_ca');
update hierarchy set name='deb53f97-9829-47b9-99cb' where id = (select id from conceptauthorities_common where shortidentifier='research_ca');

-- Location
update hierarchy set name='dbf254e8-437d-4926-be5d' where id = (select id from locationauthorities_common where shortidentifier='location');

-- Organization
update hierarchy set name='2a6f6156-2a66-4928-a0d2' where id = (select id from orgauthorities_common where shortidentifier='collector');
update hierarchy set name='4f0fd8c8-5cc7-420f-9361' where id = (select id from orgauthorities_common where shortidentifier='group_org');
update hierarchy set name='9caa4313-5ca9-42ce-8a43' where id = (select id from orgauthorities_common where shortidentifier='organization');

-- Person
update hierarchy set name='47a26a84-0e17-4e65-be6a' where id = (select id from personauthorities_common where shortidentifier='person');

-- Place
update hierarchy set name='a4925f2a-719a-4744-b67a' where id = (select id from placeauthorities_common where shortidentifier='place');

-- Taxon
update hierarchy set name='47c2a276-868b-482d-888d' where id = (select id from taxonomyauthority_common where shortidentifier='common');
update hierarchy set name='e773d53a-d65b-4b6a-bd2c' where id = (select id from taxonomyauthority_common where shortidentifier='plantsales');
update hierarchy set name='c1662cc5-d458-4788-96ed' where id = (select id from taxonomyauthority_common where shortidentifier='taxon');
