# dest.prereq: db/changes/1532715116_quiz_status

ALTER TABLE quiz ADD COLUMN meet VARCHAR(64) NOT NULL DEFAULT "Unnamed" AFTER user_id;
ALTER TABLE quiz CHANGE COLUMN name name VARCHAR(64) NOT NULL DEFAULT "Unnamed";
