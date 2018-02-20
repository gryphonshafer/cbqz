SELECT (
    IF(
        ( SELECT IF( (
            SELECT column_type
            FROM information_schema.columns
            WHERE table_schema = DATABASE() AND table_name = "role" AND column_name = "type"
        ) = "enum('Administrator','Director','Official','User')", 1, 0 ) ) +
        ( SELECT IF( (
            SELECT column_type
            FROM information_schema.columns
            WHERE table_schema = DATABASE() AND table_name = "role" AND column_name = "program_id"
        ) = "int(10) unsigned", 1, 0 ) )
        = 2, 1, 0
    )
);
