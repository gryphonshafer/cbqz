SELECT DATABASE() INTO @db;

SELECT column_type INTO @username
FROM information_schema.columns
WHERE table_schema = @db AND table_name = "user" AND column_name = "username";

SELECT column_type INTO @realname
FROM information_schema.columns
WHERE table_schema = @db AND table_name = "user" AND column_name = "realname";

SELECT (
    IF(
        ( SELECT IF( @username = "varchar(64)", 1, 0 ) ) +
        ( SELECT IF( @realname = "varchar(64)", 1, 0 ) )
        = 2, 1, 0
    )
) AS test;
