use utf8;
package CBQZ::Db::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CBQZ::Db::Schema::Result::User

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 passwd

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 realname

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 last_login

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 last_modified

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '1970-01-01 00:00:00'
  is_nullable: 0

=head2 active

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "passwd",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "realname",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "last_login",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
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
    default_value => "1970-01-01 00:00:00",
    is_nullable => 0,
  },
  "active",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("name", ["username"]);

=head1 RELATIONS

=head2 events

Type: has_many

Related object: L<CBQZ::Db::Schema::Result::Event>

=cut

__PACKAGE__->has_many(
  "events",
  "CBQZ::Db::Schema::Result::Event",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 question_sets

Type: has_many

Related object: L<CBQZ::Db::Schema::Result::QuestionSet>

=cut

__PACKAGE__->has_many(
  "question_sets",
  "CBQZ::Db::Schema::Result::QuestionSet",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 roles

Type: has_many

Related object: L<CBQZ::Db::Schema::Result::Role>

=cut

__PACKAGE__->has_many(
  "roles",
  "CBQZ::Db::Schema::Result::Role",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_programs

Type: has_many

Related object: L<CBQZ::Db::Schema::Result::UserProgram>

=cut

__PACKAGE__->has_many(
  "user_programs",
  "CBQZ::Db::Schema::Result::UserProgram",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head1 L<Moose> ROLES APPLIED

=over 4

=item * L<CBQZ::Db::Base::Result::User>

=back

=cut


with 'CBQZ::Db::Base::Result::User';


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-02-08 16:12:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:naf1prZe0pE1a7LUjs+7bQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
