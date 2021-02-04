package CBQZ::Model;

use Moose;
use MooseX::ClassAttribute;
use exact;

use CBQZ::Db::Schema;

extends 'CBQZ';

class_has db => (
    isa     => 'CBQZ::Db::Schema',
    is      => 'ro',
    lazy    => 1,
    default => sub { CBQZ::Db::Schema->connect },
);

class_has 'schema_name' => ( isa => 'Str', is => 'rw', default => '' );

has obj => ( isa => 'DBIx::Class::Row', is => 'rw' );

sub load ( $self, @params ) {
    try {
        $self->obj( $self->db->resultset( $self->schema_name )->find(@params) );
    }
    catch {
        E->throw( 'Failed to load object from database given PK: ' . ( $_ || $@ ) );
    };

    return $self;
}

sub rs ( $self, $schema_name = undef, @params ) {
    my $rs = $self->db->resultset( $schema_name || $self->schema_name );
    return (@params) ? $rs->search(@params) : $rs;
}

sub create ( $self, $params ) {
    $self->obj( $self->rs->create($params)->get_from_storage );
    return $self;
}

sub data ($self) {
    return ( $self->obj ) ? { $self->obj->get_inflated_columns } : {};
}

sub model ( $self, @names ) {
    my $models = [
        map {
            my $new_model_object = $self->new;
            $new_model_object->obj($_);
            $new_model_object;
        }
        map { ( ref $_ eq 'ARRAY' ) ? @$_ : $_ } @names
    ];
    return (wantarray) ? @$models : $models;
}

sub every ( $self, @params ) {
    my $every = $self->model( $self->rs( $self->schema_name, @params )->all );
    return (wantarray) ? @$every : $every;
}

sub every_data ( $self, @params ) {
    my $data = [ map { $_->data } @{ $self->every(@params) } ];
    return (wantarray) ? @$data : $data;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

CBQZ::Model

=head1 SYNOPSIS

    use CBQZ::Model::Thing;
    my $thing = CBQZ::Model::Thing->new;

    $thing->load(42);

    my $rs1 = $thing->db->resultset('thing')->search;
    my $rs2 = $thing->rs->search;

    say $thing->obj->id;

    my $new_thing     = CBQZ::Model::Thing->new->create({ answer => 42 });
    my $thing_hashref = $new_thing->data;

    my @things1     = $thing->model( $thing->db->rs('thing')->all );
    my @things2     = $thing->every;
    my @things_data = $thing->every_data;

=head1 DESCRIPTION

This is the parent class to the model layer. As such, it's very likely you don't
want to instantiate this class or directly work with it but rather inherit from
it in a subclass. Therefore, within this documentation, we're going to be
working with the fake module CBQZ::Model::Thing which inherits from CBQZ::Model.

=head1 PROPERTIES

The following are the properties of this class.

=head2 db

This is a class-level/singleton property that is a connection to the database
through a L<DBIx::Class> schema connection from L<CBQZ::Db::Schema>.

    my $db1 = CBQZ::Model::Thing->new->db;

    use CBQZ::Db::Schema;
    my $db2 = CBQZ::Db::Schema->connect;

In the above, C<$db1> and C<$db2> are equivalent.

=head2 obj

This is an object-level property that may contain a L<DBIx::Class::Row> of the
model's database table.

    say CBQZ::Model::Thing->new->load(42)->obj->id;

Instantiated objects from the model layer may be loaded or not-yet-loaded with
a row of data from the database. (Some model objects may not even have an
associated table and therefore can never said to be "loaded" with a row's data).
When a model object is first instantiated, it's not loaded. After being loaded
with data, the C<obj> property will contain a L<DBIx::Class::Row>.

=head1 METHODS

The following are methods of this class.

=head2 load

This method loads a database table row into the instantiated model object,
making that L<DBIx::Class::Row> available via C<obj>. The C<load> method expects
a primary key ID.

    say CBQZ::Model::Thing->new->load(42)->obj->id;

=head2 rs

This method returns a L<DBIx::Class> recordset either based on the schema name
from the current object or by schema name provided.

    my $thing_rs = CBQZ::Model::Thing->new->rs;
    my $stuff_rs = CBQZ::Model::Thing->new->rs('stuff');

    my $stuff_rs_with_params = CBQZ::Model::Thing->new->rs( 'stuff', @params );

=head2 create

This method creates a new record in the database and loads it into the current
method object.

    my $thing = CBQZ::Model::Thing->new->create({ answer => 42 });

=head2 data

Returns a hashref of column data from the row of the model object.

    my $thing_hashref = $new_thing->data;

=head2 model

Returns an array or arrayref (depending on context) of model objects loaded with
row data. It's useful if you've for if you have a recordset of L<DBIx::Class>
data and need to use the objects in their model context.

    my @things = $thing->model( $thing->db->rs('thing')->all );

=head2 every

Returns an array or arrayref (depending on context) of loaded model objects.

    my @all_things = $thing->every;

=head2 every_data

Returns an array or arrayref (depending on context) of hashrefs of data of a
given schema name.

    my @things_data = $thing->every_data;
