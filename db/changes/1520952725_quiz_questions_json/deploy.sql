# dest.prereq: db/changes/1520617866_quizzes

ALTER TABLE quiz ADD COLUMN questions MEDIUMTEXT NULL AFTER metadata;
