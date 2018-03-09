use utf8;
package CBQZ::Db::Schema::Result::QuizQuestion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CBQZ::Db::Schema::Result::QuizQuestion

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<quiz_question>

=cut

__PACKAGE__->table("quiz_question");

=head1 ACCESSORS

=head2 quiz_question_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 question_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 book

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 chapter

  data_type: 'tinyint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 verse

  data_type: 'tinyint'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 question

  data_type: 'text'
  is_nullable: 1

=head2 answer

  data_type: 'text'
  is_nullable: 1

=head2 type

  data_type: 'tinytext'
  is_nullable: 1

=head2 score

  data_type: 'decimal'
  extra: {unsigned => 1}
  is_nullable: 1
  size: [3,1]

=head2 question_as

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 question_number

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 team

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 quizzer

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 result

  data_type: 'enum'
  extra: {list => ["success","failure","none"]}
  is_nullable: 1

=head2 form

  data_type: 'enum'
  default_value: 'question'
  extra: {list => ["question","foul","timeout","sub-in","sub-out","challenge"]}
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "quiz_question_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "question_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "book",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "chapter",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 1 },
  "verse",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 1 },
  "question",
  { data_type => "text", is_nullable => 1 },
  "answer",
  { data_type => "text", is_nullable => 1 },
  "type",
  { data_type => "tinytext", is_nullable => 1 },
  "score",
  {
    data_type => "decimal",
    extra => { unsigned => 1 },
    is_nullable => 1,
    size => [3, 1],
  },
  "question_as",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "question_number",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "team",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "quizzer",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "result",
  {
    data_type => "enum",
    extra => { list => ["success", "failure", "none"] },
    is_nullable => 1,
  },
  "form",
  {
    data_type => "enum",
    default_value => "question",
    extra => {
      list => ["question", "foul", "timeout", "sub-in", "sub-out", "challenge"],
    },
    is_nullable => 0,
  },
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</quiz_question_id>

=back

=cut

__PACKAGE__->set_primary_key("quiz_question_id");

=head1 RELATIONS

=head2 question

Type: belongs_to

Related object: L<CBQZ::Db::Schema::Result::Question>

=cut

__PACKAGE__->belongs_to(
  "question",
  "CBQZ::Db::Schema::Result::Question",
  { question_id => "question_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-03-09 10:22:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iigaoh9M+Ot9XoX53deyoQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
