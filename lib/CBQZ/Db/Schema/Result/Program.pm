use utf8;
package CBQZ::Db::Schema::Result::Program;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CBQZ::Db::Schema::Result::Program

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<program>

=cut

__PACKAGE__->table("program");

=head1 ACCESSORS

=head2 program_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 question_types

  data_type: 'tinytext'
  is_nullable: 1

=head2 target_questions

  data_type: 'tinyint'
  default_value: 40
  extra: {unsigned => 1}
  is_nullable: 0

=head2 result_operation

  data_type: 'text'
  is_nullable: 1

=head2 timer_values

  data_type: 'tinytext'
  is_nullable: 1

=head2 timer_default

  data_type: 'tinyint'
  default_value: 30
  is_nullable: 0

=head2 timeout

  data_type: 'tinyint'
  default_value: 60
  is_nullable: 0

=head2 readiness

  data_type: 'tinyint'
  default_value: 20
  is_nullable: 0

=head2 as_default

  data_type: 'tinytext'
  is_nullable: 1

=head2 score_types

  data_type: 'mediumtext'
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "program_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "question_types",
  { data_type => "tinytext", is_nullable => 1 },
  "target_questions",
  {
    data_type => "tinyint",
    default_value => 40,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "result_operation",
  { data_type => "text", is_nullable => 1 },
  "timer_values",
  { data_type => "tinytext", is_nullable => 1 },
  "timer_default",
  { data_type => "tinyint", default_value => 30, is_nullable => 0 },
  "timeout",
  { data_type => "tinyint", default_value => 60, is_nullable => 0 },
  "readiness",
  { data_type => "tinyint", default_value => 20, is_nullable => 0 },
  "as_default",
  { data_type => "tinytext", is_nullable => 1 },
  "score_types",
  { data_type => "mediumtext", is_nullable => 0 },
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

=item * L</program_id>

=back

=cut

__PACKAGE__->set_primary_key("program_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 quizzes

Type: has_many

Related object: L<CBQZ::Db::Schema::Result::Quiz>

=cut

__PACKAGE__->has_many(
  "quizzes",
  "CBQZ::Db::Schema::Result::Quiz",
  { "foreign.program_id" => "self.program_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_programs

Type: has_many

Related object: L<CBQZ::Db::Schema::Result::UserProgram>

=cut

__PACKAGE__->has_many(
  "user_programs",
  "CBQZ::Db::Schema::Result::UserProgram",
  { "foreign.program_id" => "self.program_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-05-16 15:29:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v9iiywjpRbcA3GorLDN5IA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
