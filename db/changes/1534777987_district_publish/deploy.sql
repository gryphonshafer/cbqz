# dest.prereq: db/changes/1528823624_lc_enums

ALTER TABLE user_question_set DROP FOREIGN KEY IF EXISTS user_question_set_ibfk_2;
ALTER TABLE user_question_set DROP FOREIGN KEY IF EXISTS user_question_set_ibfk_1;
ALTER TABLE user_question_set DROP PRIMARY KEY;

ALTER TABLE user_question_set ADD COLUMN
    user_question_set_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;

ALTER TABLE user_question_set ALTER user_id DROP DEFAULT;
ALTER TABLE user_question_set CHANGE COLUMN user_id
    user_id INTEGER UNSIGNED NULL AFTER user_question_set_id;

ALTER TABLE user_question_set ADD INDEX user_id (user_id);

ALTER TABLE user_question_set ADD CONSTRAINT user_question_set_ibfk_1
    FOREIGN KEY (user_id) REFERENCES user (user_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE user_question_set ADD CONSTRAINT user_question_set_ibfk_2
    FOREIGN KEY (question_set_id) REFERENCES question_set (question_set_id)
        ON DELETE CASCADE ON UPDATE CASCADE;
