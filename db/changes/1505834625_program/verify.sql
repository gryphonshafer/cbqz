SELECT DATABASE() INTO @db;

SELECT ( IF (
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @db AND table_name = 'program' ) +
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @db AND table_name = 'user_program' )
    = 2, 1, 0
) ) AS test;
