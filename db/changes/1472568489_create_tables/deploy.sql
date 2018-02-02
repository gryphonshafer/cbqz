# dest.prereq: config/changes/1472567336_db_create

CREATE TABLE user (
    user_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(64) NULL,
    passwd VARCHAR(64) NULL,
    email VARCHAR(64) NULL,
    last_login TIMESTAMP NULL,
    last_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created TIMESTAMP NOT NULL DEFAULT '1970-01-01 08:00:00',
    active BOOL NOT NULL DEFAULT 1,
PRIMARY KEY(user_id),
UNIQUE INDEX name(name)
) ENGINE=InnoDB CHARSET=utf8;

CREATE TRIGGER user_before_insert BEFORE INSERT ON user FOR EACH ROW SET NEW.created = NOW();

CREATE TABLE event (
    event_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INTEGER UNSIGNED NOT NULL,
    type ENUM( 'create_user', 'login', 'login_fail', 'role_change' ) NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY(event_id),
INDEX user(user_id),
FOREIGN KEY(user_id)
    REFERENCES user(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE role (
    role_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INTEGER UNSIGNED NOT NULL,
    type ENUM( 'admin', 'director', 'quizmaster', 'scorekeeper', 'coach' ) NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY(role_id),
INDEX user(user_id),
UNIQUE INDEX user_type(user_id, type),
FOREIGN KEY(user_id)
    REFERENCES user(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE material_set (
    material_set_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(64) NULL,
    last_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created TIMESTAMP NOT NULL DEFAULT '1970-01-01 08:00:00',
PRIMARY KEY(material_set_id),
UNIQUE INDEX name(name)
) ENGINE=InnoDB CHARSET=utf8;

CREATE TRIGGER material_set_before_insert BEFORE INSERT ON material_set FOR EACH ROW SET NEW.created = NOW();

CREATE TABLE material (
    material_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    material_set_id INTEGER UNSIGNED NOT NULL,
    book VARCHAR(32) NULL,
    chapter TINYINT UNSIGNED NULL,
    verse TINYINT UNSIGNED NULL,
    text TEXT NULL,
    key_class ENUM( 'solo', 'range' ) NULL,
    key_type TINYTEXT NULL,
    is_new_para BOOL NOT NULL DEFAULT 0,
PRIMARY KEY(material_id),
UNIQUE INDEX reference( material_set_id, book, chapter, verse ),
FOREIGN KEY(material_set_id)
    REFERENCES material_set(material_set_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB CHARSET=utf8;

CREATE TABLE question_set (
    question_set_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INTEGER UNSIGNED NOT NULL,
    name VARCHAR(64) NULL,
    last_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created TIMESTAMP NOT NULL DEFAULT '1970-01-01 08:00:00',
PRIMARY KEY(question_set_id),
UNIQUE INDEX name(name),
FOREIGN KEY(user_id)
    REFERENCES user(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB CHARSET=utf8;

CREATE TRIGGER question_set_before_insert BEFORE INSERT ON question_set FOR EACH ROW SET NEW.created = NOW();

CREATE TABLE question (
    question_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    question_set_id INTEGER UNSIGNED NOT NULL,
    book VARCHAR(32) NULL,
    chapter TINYINT UNSIGNED NULL,
    verse TINYINT UNSIGNED NULL,
    question TEXT NULL,
    answer TEXT NULL,
    type TINYTEXT NULL,
    used TINYINT UNSIGNED NOT NULL DEFAULT 0,
PRIMARY KEY(question_id),
INDEX reference( book, chapter, verse ),
FOREIGN KEY(question_set_id)
    REFERENCES question_set(question_set_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB CHARSET=utf8;

CREATE TRIGGER question_after_insert AFTER INSERT ON question
FOR EACH ROW
UPDATE question_set SET last_modified = NOW() WHERE question_set_id = NEW.question_set_id;

CREATE TRIGGER question_after_update AFTER UPDATE ON question
FOR EACH ROW
UPDATE question_set SET last_modified = NOW() WHERE question_set_id IN ( NEW.question_set_id, OLD.question_set_id );

CREATE TRIGGER question_after_delete AFTER DELETE ON question
FOR EACH ROW
UPDATE question_set SET last_modified = NOW() WHERE question_set_id = OLD.question_set_id;
