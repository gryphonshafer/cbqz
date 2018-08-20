DELETE FROM user_question_set WHERE user_id IS NULL;

ALTER TABLE user_question_set
    DROP FOREIGN KEY user_question_set_ibfk_1,
    DROP FOREIGN KEY user_question_set_ibfk_2,
    CHANGE COLUMN user_id user_id INTEGER UNSIGNED NOT NULL FIRST,
    DROP COLUMN user_question_set_id,
    DROP INDEX user_id,
    DROP PRIMARY KEY,
    ADD PRIMARY KEY ( user_id, question_set_id, type ),
    DROP INDEX question_set_id,
    ADD INDEX question_set_id (question_set_id);

ALTER TABLE user_question_set ADD CONSTRAINT user_question_set_ibfk_1
    FOREIGN KEY (user_id) REFERENCES user (user_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE user_question_set ADD CONSTRAINT user_question_set_ibfk_2
    FOREIGN KEY (question_set_id) REFERENCES question_set (question_set_id)
        ON DELETE CASCADE ON UPDATE CASCADE;
