CREATE TABLE event (
    event_id int(10) unsigned NOT NULL,
    user_id int(10) unsigned NOT NULL,
    type enum('login','login_fail','challenged','challenge_fail') DEFAULT NULL,
    created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id),
    KEY user (user_id),
    CONSTRAINT event_ibfk_1 FOREIGN KEY (user_id) REFERENCES user (user_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE role (
    role_id int(10) unsigned NOT NULL,
    user_id int(10) unsigned NOT NULL,
    type enum('money','admin') DEFAULT NULL,
    created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id),
    UNIQUE KEY user_type (user_id,type),
    KEY user (user_id),
    CONSTRAINT role_ibfk_1 FOREIGN KEY (user_id) REFERENCES user (user_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE user (
    user_id int(10) unsigned NOT NULL,
    name varchar(32) NOT NULL,
    passwd varchar(40) NOT NULL,
    last_login timestamp NULL DEFAULT NULL,
    last_modified timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created timestamp NOT NULL DEFAULT '1970-01-01 08:00:00',
    active tinyint(1) NOT NULL DEFAULT '1',
    PRIMARY KEY (user_id),
    UNIQUE KEY name (name)
);

CREATE TRIGGER user_before_insert BEFORE INSERT ON user FOR EACH ROW SET NEW.created = NOW();

