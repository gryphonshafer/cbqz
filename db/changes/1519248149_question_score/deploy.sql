# dest.prereq: db/changes/1472568489_create_tables

ALTER TABLE question ADD COLUMN score DECIMAL(3,1) UNSIGNED NULL AFTER marked;
