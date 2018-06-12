ALTER TABLE event CHANGE COLUMN type
    type ENUM( 'create_user', 'login', 'login_fail', 'role_change' )
    NOT NULL AFTER user_id;
