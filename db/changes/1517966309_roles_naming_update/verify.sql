SELECT DATABASE() INTO @db;

SELECT column_type INTO @type
FROM information_schema.columns
WHERE table_schema = @db AND table_name = "role" AND column_name = "type";

SELECT column_type INTO @program
FROM information_schema.columns
WHERE table_schema = @db AND table_name = "role" AND column_name = "program_id";

SELECT (
    IF(
        ( SELECT IF( @type = "enum('Administrator','Director','Official','User')", 1, 0 ) ) +
        ( SELECT IF( @program = "int(10) unsigned", 1, 0 ) )
        = 2, 1, 0
    )
) AS test;
