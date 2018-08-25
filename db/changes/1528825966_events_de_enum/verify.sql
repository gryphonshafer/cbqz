SELECT IF (
    (
        SELECT column_type FROM information_schema.columns
        WHERE table_schema = DATABASE()
        AND table_name = 'event'
        AND column_name = 'type'
    ) = "tinytext", 1, 0
);

