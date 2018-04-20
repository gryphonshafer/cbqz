ALTER TABLE program DROP COLUMN timeout;
ALTER TABLE program DROP COLUMN readiness;

DROP TRIGGER IF EXISTS quiz_before_insert;

DROP TABLE IF EXISTS quiz_question;
DROP TABLE IF EXISTS quiz;
