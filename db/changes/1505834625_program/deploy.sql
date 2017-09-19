# dest.prereq: db/changes/1472568489_create_tables

CREATE TABLE program (
    program_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(64) NULL,
    created TIMESTAMP NOT NULL DEFAULT '1970-01-01 00:00:00',
PRIMARY KEY(program_id),
UNIQUE INDEX name(name)
) ENGINE=InnoDB CHARSET=utf8;

CREATE TABLE user_program (
    user_id INTEGER UNSIGNED NOT NULL,
    program_id INTEGER UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT '1970-01-01 00:00:00',
PRIMARY KEY( user_id, program_id ),
FOREIGN KEY (user_id)
    REFERENCES user(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
FOREIGN KEY (program_id)
    REFERENCES program(program_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB CHARSET=utf8;
