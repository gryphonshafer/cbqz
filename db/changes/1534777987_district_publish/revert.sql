DELETE FROM user_question_set WHERE user_id IS NULL;

ALTER TABLE user_question_set DROP FOREIGN KEY IF EXISTS user_question_set_ibfk_2;
ALTER TABLE user_question_set DROP FOREIGN KEY IF EXISTS user_question_set_ibfk_1;

ALTER TABLE user_question_set DROP INDEX user_id;
ALTER TABLE user_question_set DROP INDEX user_question_set_ibfk_2;

ALTER TABLE user_question_set DROP COLUMN user_question_set_id;

ALTER TABLE user_question_set CHANGE COLUMN user_id user_id INTEGER UNSIGNED NOT NULL FIRST;
ALTER TABLE user_question_set ADD PRIMARY KEY ( user_id, question_set_id, type );

ALTER TABLE user_question_set ADD INDEX question_set_id (question_set_id);

ALTER TABLE user_question_set ADD CONSTRAINT user_question_set_ibfk_1
    FOREIGN KEY (user_id) REFERENCES user (user_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE user_question_set ADD CONSTRAINT user_question_set_ibfk_2
    FOREIGN KEY (question_set_id) REFERENCES question_set (question_set_id)
        ON DELETE CASCADE ON UPDATE CASCADE;
