package CBQZ::Model;

use Moose;
use MooseX::ClassAttribute;
use exact;
use Try::Tiny;

use CBQZ::Db::Schema;

extends 'CBQZ';

class_has db => (
    isa     => 'CBQZ::Db::Schema',
    is      => 'ro',
    lazy    => 1,
    default => sub { CBQZ::Db::Schema->connect },
);

has obj => ( isa => 'DBIx::Class::Row', is => 'rw' );

sub load ( $self, @params ) {
    try {
        $self->obj( $self->db->resultset( $self->schema_name )->find(@params) );
    }
    catch {
        E->throw( 'Failed to load object from database given PK: ' . $_ );
    };

    return $self;
}

sub rs ( $self, $schema_name = undef, @params ) {
    my $rs = $self->db->resultset( $schema_name || $self->schema_name );
    return (@params) ? $rs->search(@params) : $rs;
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

sub every ( $self, @sets ) {
    my $every = $self->model( $self->rs(@sets)->all );
    return (wantarray) ? @$every : $every;
}

sub every_data ( $self, @sets ) {
    my $data = [ map { $_->data } @{ $self->every(@sets) } ];
    return (wantarray) ? @$data : $data;
}

__PACKAGE__->meta->make_immutable;

1;
