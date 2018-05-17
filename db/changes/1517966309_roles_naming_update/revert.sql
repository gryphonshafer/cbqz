# dest.postreq: db/changes/1472568489_create_tables

LOCK TABLES role WRITE;

ALTER TABLE role DROP INDEX user_program_type;
ALTER TABLE role DROP COLUMN program_id;
ALTER TABLE role CHANGE type type TEXT;

UPDATE role SET type = "admin" WHERE type = "Administrator";
UPDATE role SET type = "director" WHERE type = "Director";
UPDATE role SET type = "quizmaster" WHERE type = "Official";
UPDATE role SET type = "coach" WHERE type = "User";

ALTER TABLE role CHANGE type type ENUM( "admin", "director", "quizmaster", "scorekeeper", "coach" ) NOT NULL;
ALTER TABLE role ADD UNIQUE INDEX user_type( user_id, type );

UNLOCK TABLES;
