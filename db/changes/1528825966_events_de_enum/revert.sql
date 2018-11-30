# dest.postreq: db/changes/1472568489_create_tables

ALTER TABLE event CHANGE COLUMN type
    type ENUM( 'create_user', 'login', 'login_fail', 'role_change' )
    NOT NULL AFTER user_id;
