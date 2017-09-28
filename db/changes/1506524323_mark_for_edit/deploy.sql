# dest.prereq: db/changes/1472568489_create_tables

ALTER TABLE question ADD COLUMN marked TEXT NULL AFTER used;
