# dest.prereq: db/changes/1472568489_create_tables

ALTER TABLE material_set ADD COLUMN book_order VARCHAR(128) NULL DEFAULT NULL AFTER name;
