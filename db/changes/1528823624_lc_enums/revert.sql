# dest.postreq: db/changes/1517966309_roles_naming_update
# dest.postreq: db/changes/1519065946_publish_question_sets

ALTER TABLE role CHANGE COLUMN type
    type ENUM( 'Administrator', 'Director', 'Official', 'User' ) NOT NULL AFTER program_id;

ALTER TABLE user_question_set CHANGE COLUMN type
    type ENUM( 'Publish', 'Share' ) NOT NULL AFTER question_set_id;
