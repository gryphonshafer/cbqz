SELECT ( IF (
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'quiz' ) +
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'quiz_question' ) +
    ( SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = DATABASE() AND trigger_name = 'quiz_before_insert' )
    = 3, 1, 0
) );
