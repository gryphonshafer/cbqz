SELECT ( IF (
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'socket' ) +
    ( SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = DATABASE() AND trigger_name = 'socket_before_insert' )
    = 2, 1, 0
) );
