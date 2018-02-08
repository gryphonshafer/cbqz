# dest.prereq: db/changes/1472568489_create_tables

LOCK TABLES role WRITE;

ALTER TABLE role DROP INDEX user_type;
ALTER TABLE role CHANGE type type TEXT;

UPDATE role SET type = "Administrator" WHERE type = "admin";
UPDATE role SET type = "Director" WHERE type = "director";
UPDATE role SET type = "Official" WHERE type IN ( "quizmaster", "scorekeeper" );
UPDATE role SET type = "User" WHERE type = "coach";

ALTER TABLE role CHANGE type type ENUM( "Administrator", "Director", "Official", "User" ) NOT NULL;

ALTER TABLE role ADD COLUMN program_id INTEGER UNSIGNED NULL AFTER user_id;
ALTER TABLE role ADD UNIQUE INDEX user_program_type( user_id, program_id, type );

UPDATE role SET program_id = 1 WHERE type != "Administrator";
UPDATE role SET program_id = NULL WHERE type = "Administrator";

UNLOCK TABLES;
