SELECT (
    IF(
        ( SELECT IF( (
            SELECT column_type
            FROM information_schema.columns
            WHERE table_schema = DATABASE() AND table_name = "program" AND column_name = "randomize_first"
        ) = "tinyint(3) unsigned", 1, 0 ) )
        = 1, 1, 0
    )
);
