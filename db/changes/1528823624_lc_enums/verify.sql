SELECT IF (
    IF (
        (
            SELECT column_type FROM information_schema.columns
            WHERE table_schema = DATABASE()
            AND table_name = 'role'
            AND column_name = 'type'
        ) = "enum('administrator','director','official','user')", 1, 0
    ) +
    IF (
        (
            SELECT column_type FROM information_schema.columns
            WHERE table_schema = DATABASE()
            AND table_name = 'user_question_set'
            AND column_name = 'type'
        ) = "enum('publish','share')", 1, 0
    ) = 2, 1, 0
);
