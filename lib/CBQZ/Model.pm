package CBQZ::Model;

use Moose;
use MooseX::ClassAttribute;
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

sub load {
    my $self = shift;
    my @params = @_;

    try {
        $self->obj( $self->db->resultset( $self->schema_name )->find(@params) );
    }
    catch {
        E->throw( 'Failed to load object from database given PK: ' . $_ );
    };

    return $self;
}

sub rs {
    my $self = shift;
    return $self->db->resultset( shift || $self->schema_name );
}

__PACKAGE__->meta->make_immutable;

1;
