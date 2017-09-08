use utf8;
package CBQZ::Db::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'CBQZ::Db';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-09-07 17:04:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Z/jHhHnTUfg8qiAGqoiopg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
