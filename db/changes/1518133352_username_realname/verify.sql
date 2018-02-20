SELECT (
    IF(
        ( SELECT IF( (
            SELECT column_type
            FROM information_schema.columns
            WHERE table_schema = DATABASE() AND table_name = "user" AND column_name = "username"
        ) = "varchar(64)", 1, 0 ) ) +
        ( SELECT IF( (
            SELECT column_type
            FROM information_schema.columns
            WHERE table_schema = DATABASE() AND table_name = "user" AND column_name = "realname"
        ) = "varchar(64)", 1, 0 ) )
        = 2, 1, 0
    )
);
