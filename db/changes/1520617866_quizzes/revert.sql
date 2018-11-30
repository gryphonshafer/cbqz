# dest.postreq: db/changes/1505834625_program

ALTER TABLE program DROP COLUMN timeout;
ALTER TABLE program DROP COLUMN readiness;
ALTER TABLE program DROP COLUMN score_types;

DROP TRIGGER IF EXISTS quiz_before_insert;

DROP TABLE IF EXISTS quiz_question;
DROP TABLE IF EXISTS quiz;
