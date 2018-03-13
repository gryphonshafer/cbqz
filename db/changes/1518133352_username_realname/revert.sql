# dest.postreq: db/changes/1472568489_create_tables

ALTER TABLE user CHANGE COLUMN username name VARCHAR(64) NULL DEFAULT NULL AFTER user_id;
ALTER TABLE user DROP COLUMN realname;
