# dest.prereq: db/changes/1472568489_create_tables/deploy.sql

ALTER TABLE event CHANGE COLUMN type type TINYTEXT NOT NULL AFTER user_id;
