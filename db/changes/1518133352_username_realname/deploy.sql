# dest.prereq: db/changes/1472568489_create_tables

ALTER TABLE user CHANGE COLUMN name username VARCHAR(64) NULL DEFAULT NULL AFTER user_id;
ALTER TABLE user ADD COLUMN realname VARCHAR(64) NULL DEFAULT NULL AFTER passwd;
