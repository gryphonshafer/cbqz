use utf8;
package CBQZ::Db::Schema::Result::UserQuestionSet;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CBQZ::Db::Schema::Result::UserQuestionSet

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<user_question_set>

=cut

__PACKAGE__->table("user_question_set");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 question_set_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 type

  data_type: 'enum'
  extra: {list => ["Publish","Share"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "question_set_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "type",
  {
    data_type => "enum",
    extra => { list => ["Publish", "Share"] },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</question_set_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id", "question_set_id");

=head1 RELATIONS

=head2 question_set

Type: belongs_to

Related object: L<CBQZ::Db::Schema::Result::QuestionSet>

=cut

__PACKAGE__->belongs_to(
  "question_set",
  "CBQZ::Db::Schema::Result::QuestionSet",
  { question_set_id => "question_set_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 user

Type: belongs_to

Related object: L<CBQZ::Db::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "CBQZ::Db::Schema::Result::User",
  { user_id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-02-19 12:59:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+wlVvfGSNPmWgHaV6uRglw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
