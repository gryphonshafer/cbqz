# dest.prereq: db/changes/1472568489_create_tables

ALTER TABLE event CHANGE COLUMN type type TINYTEXT NOT NULL AFTER user_id;
