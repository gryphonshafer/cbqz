# dest.prereq: db/changes/1505834625_program

CREATE TABLE quiz (
    quiz_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    program_id INTEGER UNSIGNED NOT NULL,
    user_id INTEGER UNSIGNED NULL,
    name VARCHAR(64),
    state ENUM( 'pending', 'active', 'closed' ) NOT NULL DEFAULT 'pending',
    quizmaster VARCHAR(64),
    room TINYINT UNSIGNED NOT NULL DEFAULT 1,
    official BOOL NOT NULL DEFAULT 0,
    scheduled DATETIME NULL,
    metadata MEDIUMTEXT NULL,
    questions MEDIUMTEXT NULL,
    result_operation MEDIUMTEXT NULL,
    last_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created TIMESTAMP NOT NULL DEFAULT '1970-01-01 08:00:00',
PRIMARY KEY(quiz_id),
FOREIGN KEY(program_id)
    REFERENCES program(program_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
FOREIGN KEY(user_id)
    REFERENCES user(user_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB CHARSET=utf8;

CREATE TRIGGER quiz_before_insert BEFORE INSERT ON quiz FOR EACH ROW SET NEW.created = NOW();

CREATE TABLE quiz_question (
    quiz_question_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    quiz_id INTEGER UNSIGNED NULL,
    question_id INTEGER UNSIGNED NULL,
    book VARCHAR(32) NULL,
    chapter TINYINT UNSIGNED NULL,
    verse TINYINT UNSIGNED NULL,
    question TEXT NULL,
    answer TEXT NULL,
    type TINYTEXT NULL,
    score DECIMAL(3,1) UNSIGNED NULL,
    question_as VARCHAR(16) NULL,
    question_number VARCHAR(16) NULL,
    team VARCHAR(64) NULL,
    quizzer VARCHAR(64) NULL,
    result ENUM( 'success', 'failure', 'none' ) NULL,
    form ENUM(
        'question', 'foul', 'timeout', 'sub-in', 'sub-out', 'challenge', 'readiness', 'unsportsmanlike'
    ) NOT NULL DEFAULT 'question',
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY(quiz_question_id),
FOREIGN KEY(quiz_id)
    REFERENCES quiz(quiz_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
FOREIGN KEY(question_id)
    REFERENCES question(question_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB CHARSET=utf8;

ALTER TABLE program ADD COLUMN timeout TINYINT NOT NULL DEFAULT 60 AFTER timer_default;
ALTER TABLE program ADD COLUMN readiness TINYINT NOT NULL DEFAULT 20 AFTER timeout;
ALTER TABLE program ADD COLUMN score_types MEDIUMTEXT NOT NULL AFTER as_default;

SELECT '["3-Team 20-Question","2-Team 15-Question Tie-Breaker","2-Team 20-Question"' into @score_types;
SELECT CONCAT( @score_types, ',"2-Team Overtime","3-Team Overtime"]' ) into @score_types;
UPDATE program SET score_types = @score_types;
