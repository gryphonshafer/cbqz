# dest.prereq: db/changes/1472568489_create_tables

CREATE TABLE user_question_set (
    user_id INTEGER UNSIGNED NOT NULL,
    question_set_id INTEGER UNSIGNED NOT NULL,
    type ENUM( 'Publish', 'Share' ) NOT NULL,
PRIMARY KEY( user_id, question_set_id, type ),
FOREIGN KEY (user_id)
    REFERENCES user(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
FOREIGN KEY (question_set_id)
    REFERENCES question_set(question_set_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB CHARSET=utf8;
