SELECT DATABASE() INTO @db;

SELECT column_type INTO @type
FROM information_schema.columns
WHERE table_schema = @db AND table_name = "role" AND column_name = "type";

SELECT ( IF ( @type = "enum('Administrator','Director','Official','User')", 1, 0 ) ) AS test;
