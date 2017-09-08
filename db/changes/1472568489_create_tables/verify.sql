SELECT DATABASE() INTO @db;

SELECT ( IF (
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @db AND table_name = 'user' ) +
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @db AND table_name = 'event' ) +
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @db AND table_name = 'role' ) +
    ( SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = @db AND trigger_name = 'user_before_insert' )
    = 4, 1, 0
) ) AS test;
