DROP TRIGGER IF EXISTS user_before_insert;
DROP TRIGGER IF EXISTS material_set_before_insert;
DROP TRIGGER IF EXISTS question_set_before_insert;
DROP TRIGGER IF EXISTS question_after_insert;
DROP TRIGGER IF EXISTS question_after_update;
DROP TRIGGER IF EXISTS question_after_delete;

DROP TABLE IF EXISTS question;
DROP TABLE IF EXISTS question_set;
DROP TABLE IF EXISTS material;
DROP TABLE IF EXISTS material_set;
DROP TABLE IF EXISTS event;
DROP TABLE IF EXISTS role;
DROP TABLE IF EXISTS user;
