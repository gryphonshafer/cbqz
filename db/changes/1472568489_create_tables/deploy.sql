# dest.prereq: config/changes/1472567336_db_create

CREATE TABLE user (
    user_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(32) NOT NULL,
    passwd VARCHAR(40) NOT NULL,
    last_login TIMESTAMP NULL,
    last_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created TIMESTAMP NOT NULL DEFAULT '1970-01-01 00:00:00',
    active BOOL NOT NULL DEFAULT 1,
PRIMARY KEY(user_id),
UNIQUE INDEX name(name)
) ENGINE=InnoDB CHARSET=utf8;

CREATE TRIGGER user_before_insert BEFORE INSERT ON user FOR EACH ROW SET NEW.created = NOW();

CREATE TABLE event (
    event_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INTEGER UNSIGNED NOT NULL,
    type ENUM('login','login_fail','challenged','challenge_fail'),
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
    type ENUM('money','admin'),
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY(role_id),
INDEX user(user_id),
UNIQUE INDEX user_type(user_id, type),
FOREIGN KEY(user_id)
    REFERENCES user(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;
