# dest.prereq: db/changes/1472568489_create_tables

LOCK TABLES role WRITE;

ALTER TABLE role DROP INDEX user_type;
ALTER TABLE role CHANGE type type TEXT;

UPDATE role SET type = "Administrator" WHERE type = "admin";
UPDATE role SET type = "Director" WHERE type = "director";
UPDATE role SET type = "Official" WHERE type IN ( "quizmaster", "scorekeeper" );
UPDATE role SET type = "User" WHERE type = "coach";

ALTER TABLE role CHANGE type type ENUM( "Administrator", "Director", "Official", "User" ) NOT NULL;
ALTER TABLE role ADD UNIQUE INDEX user_type(user_id, type);

UNLOCK TABLES;
