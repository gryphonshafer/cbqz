SELECT (
    IF(
        ( SELECT IF( (
            SELECT column_type
            FROM information_schema.columns
            WHERE table_schema = DATABASE() AND table_name = "question" AND column_name = "score"
        ) = "decimal(3,1) unsigned", 1, 0 ) )
        = 1, 1, 0
    )
);
