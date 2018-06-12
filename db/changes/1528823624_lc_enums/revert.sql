ALTER TABLE role CHANGE COLUMN type type ENUM(
    'Administrator', 'Director', 'Official', 'User', 'administrator', 'director', 'official', 'user'
) NOT NULL AFTER program_id;

UPDATE role SET type = CONCAT( UCASE( LEFT( type, 1 ) ), SUBSTRING( type, 2 ) );

ALTER TABLE role CHANGE COLUMN type type ENUM(
    'Administrator', 'Director', 'Official', 'User'
) NOT NULL AFTER program_id;

#-------------------------------------------------------------------------------

ALTER TABLE user_question_set CHANGE COLUMN type type ENUM(
    'Publish', 'Share', 'publish', 'share'
) NOT NULL AFTER question_set_id;

UPDATE user_question_set SET type = CONCAT( UCASE( LEFT( type, 1 ) ), SUBSTRING( type, 2 ) );

ALTER TABLE user_question_set CHANGE COLUMN type type ENUM(
    'Publish', 'Share'
) NOT NULL AFTER question_set_id;

