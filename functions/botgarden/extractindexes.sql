CREATE INDEX misc_lifecyclestate_idx ON misc (lifecyclestate) ;
CREATE INDEX taxonomicIdentGroup_taxon_idx ON taxonomicIdentGroup (taxon);
CREATE INDEX relations_common_objectdocumenttype_idx ON relations_common (objectdocumenttype);
CREATE INDEX relations_common_subjectdocumenttype_idx ON relations_common (subjectdocumenttype);
CREATE INDEX collectionobjects_naturalhistory_rare_idx ON collectionobjects_naturalhistory (rare);
CREATE INDEX collectionobjects_botgarden_deadflag_idx ON collectionobjects_botgarden (deadflag);
CREATE INDEX hierarchy_name_idx ON hierarchy (name);
CREATE INDEX hierarchy_pos_idx ON hierarchy (pos);
