-- Reset vocabulary csids to known values. This script should be run after recreating a database, and initializing authorities.

-- Concept
update hierarchy set name='96141839-4bac-4e3d-a511' where id = (select id from conceptauthorities_common where shortidentifier='class_ca');
update hierarchy set name='bbe39bb2-a622-4570-a946' where id = (select id from conceptauthorities_common where shortidentifier='concept');
update hierarchy set name='deb53f97-9829-47b9-99cb' where id = (select id from conceptauthorities_common where shortidentifier='research_ca');

-- Location
update hierarchy set name='dbf254e8-437d-4926-be5d' where id = (select id from locationauthorities_common where shortidentifier='location');

-- Organization
update hierarchy set name='b2e1fcc7-1f38-4139-9d2f' where id = (select id from orgauthorities_common where shortidentifier='determination');
update hierarchy set name='2cf8b5c6-7e0b-4c48-8efd' where id = (select id from orgauthorities_common where shortidentifier='institution');
update hierarchy set name='ede13b2d-78e3-4384-8a2e' where id = (select id from orgauthorities_common where shortidentifier='nomenclature');
update hierarchy set name='9caa4313-5ca9-42ce-8a43' where id = (select id from orgauthorities_common where shortidentifier='organization');
update hierarchy set name='4f041ba3-d83e-40e3-8e4d' where id = (select id from orgauthorities_common where shortidentifier='typeassertion');

-- Person
update hierarchy set name='47a26a84-0e17-4e65-be6a' where id = (select id from personauthorities_common where shortidentifier='person');

-- Place
update hierarchy set name='a4925f2a-719a-4744-b67a' where id = (select id from placeauthorities_common where shortidentifier='place');

-- Taxon
update hierarchy set name='47c2a276-868b-482d-888d' where id = (select id from taxonomyauthority_common where shortidentifier='common');
update hierarchy set name='c1662cc5-d458-4788-96ed' where id = (select id from taxonomyauthority_common where shortidentifier='taxon');
update hierarchy set name='2bfe55f3-b9ce-494c-900f' where id = (select id from taxonomyauthority_common where shortidentifier='unverified');
