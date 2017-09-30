CREATE TABLE event (
    event_id int(10) unsigned NOT NULL,
    user_id int(10) unsigned NOT NULL,
    type enum('create_user','login','login_fail','role_change') NOT NULL,
    created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id),
    KEY user (user_id),
    CONSTRAINT event_ibfk_1 FOREIGN KEY (user_id) REFERENCES user (user_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE material (
    material_id int(10) unsigned NOT NULL,
    material_set_id int(10) unsigned NOT NULL,
    book varchar(32) DEFAULT NULL,
    chapter tinyint(3) unsigned DEFAULT NULL,
    verse tinyint(3) unsigned DEFAULT NULL,
    text text,
    key_class enum('solo','range') DEFAULT NULL,
    key_type tinytext,
    is_new_para tinyint(1) NOT NULL DEFAULT '0',
    PRIMARY KEY (material_id),
    UNIQUE KEY reference (book,chapter,verse),
    KEY material_set_id (material_set_id),
    CONSTRAINT material_ibfk_1 FOREIGN KEY (material_set_id) REFERENCES material_set (material_set_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE material_set (
    material_set_id int(10) unsigned NOT NULL,
    name varchar(64) DEFAULT NULL,
    last_modified timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created timestamp NOT NULL DEFAULT '1970-01-01 08:00:00',
    PRIMARY KEY (material_set_id),
    UNIQUE KEY name (name)
);

CREATE TRIGGER material_set_before_insert BEFORE INSERT ON material_set FOR EACH ROW SET NEW.created = NOW();

CREATE TABLE program (
    program_id int(10) unsigned NOT NULL,
    name varchar(64) DEFAULT NULL,
    question_types tinytext,
    target_questions tinyint(3) unsigned NOT NULL DEFAULT '50',
    result_operation text,
    timer_values tinytext,
    timer_default tinyint(4) NOT NULL DEFAULT '30',
    as_default tinytext,
    created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (program_id),
    UNIQUE KEY name (name)
);

CREATE TABLE question (
    question_id int(10) unsigned NOT NULL,
    question_set_id int(10) unsigned NOT NULL,
    book varchar(32) DEFAULT NULL,
    chapter tinyint(3) unsigned DEFAULT NULL,
    verse tinyint(3) unsigned DEFAULT NULL,
    question text,
    answer text,
    type tinytext,
    used tinyint(3) unsigned NOT NULL DEFAULT '0',
    marked text,
    PRIMARY KEY (question_id),
    KEY reference (book,chapter,verse),
    KEY question_set_id (question_set_id),
    CONSTRAINT question_ibfk_1 FOREIGN KEY (question_set_id) REFERENCES question_set (question_set_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TRIGGER question_after_insert AFTER INSERT ON question
FOR EACH ROW
UPDATE question_set SET last_modified = NOW() WHERE question_set_id = NEW.question_set_id;

CREATE TRIGGER question_after_update AFTER UPDATE ON question
FOR EACH ROW
UPDATE question_set SET last_modified = NOW() WHERE question_set_id IN ( NEW.question_set_id, OLD.question_set_id );

CREATE TRIGGER question_after_delete AFTER DELETE ON question
FOR EACH ROW
UPDATE question_set SET last_modified = NOW() WHERE question_set_id = OLD.question_set_id;

CREATE TABLE question_set (
    question_set_id int(10) unsigned NOT NULL,
    user_id int(10) unsigned NOT NULL,
    name varchar(64) DEFAULT NULL,
    last_modified timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created timestamp NOT NULL DEFAULT '1970-01-01 08:00:00',
    PRIMARY KEY (question_set_id),
    UNIQUE KEY name (name),
    KEY user_id (user_id),
    CONSTRAINT question_set_ibfk_1 FOREIGN KEY (user_id) REFERENCES user (user_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TRIGGER question_set_before_insert BEFORE INSERT ON question_set FOR EACH ROW SET NEW.created = NOW();

CREATE TABLE role (
    role_id int(10) unsigned NOT NULL,
    user_id int(10) unsigned NOT NULL,
    type enum('admin','director','quizmaster','scorekeeper','coach') NOT NULL,
    created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id),
    UNIQUE KEY user_type (user_id,type),
    KEY user (user_id),
    CONSTRAINT role_ibfk_1 FOREIGN KEY (user_id) REFERENCES user (user_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE user (
    user_id int(10) unsigned NOT NULL,
    name varchar(64) DEFAULT NULL,
    passwd varchar(64) DEFAULT NULL,
    email varchar(64) DEFAULT NULL,
    last_login timestamp NULL DEFAULT NULL,
    last_modified timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created timestamp NOT NULL DEFAULT '1970-01-01 08:00:00',
    active tinyint(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (user_id),
    UNIQUE KEY name (name)
);

CREATE TRIGGER user_before_insert BEFORE INSERT ON user FOR EACH ROW SET NEW.created = NOW();

CREATE TABLE user_program (
    user_id int(10) unsigned NOT NULL,
    program_id int(10) unsigned NOT NULL,
    created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id,program_id),
    KEY program_id (program_id),
    CONSTRAINT user_program_ibfk_1 FOREIGN KEY (user_id) REFERENCES user (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT user_program_ibfk_2 FOREIGN KEY (program_id) REFERENCES program (program_id) ON DELETE CASCADE ON UPDATE CASCADE
);

