# dest.postreq: db/changes/1532715116_quiz_status

ALTER TABLE quiz DROP COLUMN meet;
ALTER TABLE quiz CHANGE COLUMN name name VARCHAR(64) NULL;
