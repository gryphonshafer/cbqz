ALTER TABLE program DROP COLUMN timeout;

DROP TRIGGER IF EXISTS quiz_before_insert;

DROP TABLE IF EXISTS quiz_question;
DROP TABLE IF EXISTS quiz;
