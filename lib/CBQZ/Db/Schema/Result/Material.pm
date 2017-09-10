use utf8;
package CBQZ::Db::Schema::Result::Material;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CBQZ::Db::Schema::Result::Material

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<material>

=cut

__PACKAGE__->table("material");

=head1 ACCESSORS

=head2 material_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 material_set_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

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

=head2 text

  data_type: 'text'
  is_nullable: 1

=head2 is_key

  data_type: 'enum'
  extra: {list => ["solo","range"]}
  is_nullable: 1

=head2 key_type

  data_type: 'tinytext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "material_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "material_set_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "book",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "chapter",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 1 },
  "verse",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 1 },
  "text",
  { data_type => "text", is_nullable => 1 },
  "is_key",
  {
    data_type => "enum",
    extra => { list => ["solo", "range"] },
    is_nullable => 1,
  },
  "key_type",
  { data_type => "tinytext", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</material_id>

=back

=cut

__PACKAGE__->set_primary_key("material_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<reference>

=over 4

=item * L</book>

=item * L</chapter>

=item * L</verse>

=back

=cut

__PACKAGE__->add_unique_constraint("reference", ["book", "chapter", "verse"]);

=head1 RELATIONS

=head2 material_set

Type: belongs_to

Related object: L<CBQZ::Db::Schema::Result::MaterialSet>

=cut

__PACKAGE__->belongs_to(
  "material_set",
  "CBQZ::Db::Schema::Result::MaterialSet",
  { material_set_id => "material_set_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-09-10 07:40:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C7DC1Rl8ymN/Ne0poe5HQw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
