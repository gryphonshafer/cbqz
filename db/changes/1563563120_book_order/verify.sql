SELECT IF( (
    SELECT column_type
    FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = "material_set" AND column_name = "book_order"
) = "varchar(128)", 1, 0 );
