SELECT ( IF (
    ( SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'user_question_set' )
    = 1, 1, 0
) );
