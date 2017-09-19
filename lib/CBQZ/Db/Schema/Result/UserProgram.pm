use utf8;
package CBQZ::Db::Schema::Result::UserProgram;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CBQZ::Db::Schema::Result::UserProgram

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<user_program>

=cut

__PACKAGE__->table("user_program");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 program_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '1970-01-01 00:00:00'
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
  "program_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "1970-01-01 00:00:00",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</program_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id", "program_id");

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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-09-19 09:42:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QB4gh+AnAva9zEGFBy+Jrw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
