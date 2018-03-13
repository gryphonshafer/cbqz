SELECT (
    IF(
        ( SELECT IF( (
            SELECT column_type
            FROM information_schema.columns
            WHERE table_schema = DATABASE() AND table_name = "quiz" AND column_name = "questions"
        ) = "mediumtext", 1, 0 ) )
        = 1, 1, 0
    )
);
