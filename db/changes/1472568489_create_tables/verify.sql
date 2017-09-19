SELECT DATABASE() INTO @db;

SELECT ( IF (
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @db AND table_name = 'user' ) +
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @db AND table_name = 'event' ) +
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @db AND table_name = 'role' ) +
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @db AND table_name = 'material_set' ) +
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @db AND table_name = 'material' ) +
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @db AND table_name = 'question_set' ) +
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @db AND table_name = 'question' ) +
    ( SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = @db AND trigger_name = 'user_before_insert' ) +
    ( SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = @db AND trigger_name = 'material_set_before_insert' ) +
    ( SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = @db AND trigger_name = 'question_set_before_insert' ) +
    ( SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = @db AND trigger_name = 'question_after_insert' ) +
    ( SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = @db AND trigger_name = 'question_after_update' ) +
    ( SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = @db AND trigger_name = 'question_after_delete' )
    = 13, 1, 0
) ) AS test;
