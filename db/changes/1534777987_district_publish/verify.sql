SELECT COUNT(*) FROM information_schema.columns WHERE
    table_schema = DATABASE() AND
    table_name = 'user_question_set' AND
    column_name = 'user_question_set_id';
