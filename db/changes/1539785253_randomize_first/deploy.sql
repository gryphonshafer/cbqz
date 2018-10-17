# dest.prereq: db/changes/1505834625_program

ALTER TABLE program ADD COLUMN randomize_first TINYINT UNSIGNED NOT NULL DEFAULT 20 AFTER target_questions;
