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

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '1970-01-01 00:00:00'
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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-09-19 09:42:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LqCTCqk3f7JkFV5HNxoeNQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
