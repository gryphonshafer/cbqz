use utf8;
package CBQZ::Db::Schema::Result::Quiz;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CBQZ::Db::Schema::Result::Quiz

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<quiz>

=cut

__PACKAGE__->table("quiz");

=head1 ACCESSORS

=head2 quiz_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 program_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 state

  data_type: 'enum'
  default_value: 'pending'
  extra: {list => ["pending","active","closed"]}
  is_nullable: 0

=head2 quizmaster

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 room

  data_type: 'tinyint'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=head2 official

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 scheduled

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 metadata

  data_type: 'mediumtext'
  is_nullable: 1

=head2 questions

  data_type: 'mediumtext'
  is_nullable: 1

=head2 result_operation

  data_type: 'mediumtext'
  is_nullable: 1

=head2 last_modified

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '1970-01-01 08:00:00'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "quiz_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "program_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "user_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "state",
  {
    data_type => "enum",
    default_value => "pending",
    extra => { list => ["pending", "active", "closed"] },
    is_nullable => 0,
  },
  "quizmaster",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "room",
  {
    data_type => "tinyint",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "official",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "scheduled",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "metadata",
  { data_type => "mediumtext", is_nullable => 1 },
  "questions",
  { data_type => "mediumtext", is_nullable => 1 },
  "result_operation",
  { data_type => "mediumtext", is_nullable => 1 },
  "last_modified",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "1970-01-01 08:00:00",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</quiz_id>

=back

=cut

__PACKAGE__->set_primary_key("quiz_id");

=head1 RELATIONS

=head2 program

Type: belongs_to

Related object: L<CBQZ::Db::Schema::Result::Program>

=cut

__PACKAGE__->belongs_to(
  "program",
  "CBQZ::Db::Schema::Result::Program",
  { program_id => "program_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 quiz_questions

Type: has_many

Related object: L<CBQZ::Db::Schema::Result::QuizQuestion>

=cut

__PACKAGE__->has_many(
  "quiz_questions",
  "CBQZ::Db::Schema::Result::QuizQuestion",
  { "foreign.quiz_id" => "self.quiz_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user

Type: belongs_to

Related object: L<CBQZ::Db::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "CBQZ::Db::Schema::Result::User",
  { user_id => "user_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-07-23 10:00:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DqhtZ7PGDFmEwV3lslifJw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
