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
    my $rs = $self->db->resultset( shift || $self->schema_name );
    return (@_) ? $rs->search(@_) : $rs;
}

sub data {
    my ($self) = @_;
    return ( $self->obj ) ? { $self->obj->get_inflated_columns } : {};
}

sub model {
    my $self = shift;

    my $models = [
        map {
            my $new_model_object = $self->new;
            $new_model_object->obj($_);
            $new_model_object;
        }
        map { ( ref $_ eq 'ARRAY' ) ? @$_ : $_ } @_
    ];
    return (wantarray) ? @$models : $models;
}

sub every {
    my $self = shift;
    my $every = $self->model( $self->rs(@_)->all );
    return (wantarray) ? @$every : $every;
}

sub every_data {
    my $self = shift;
    my $data = [ map { $_->data } @{ $self->every(@_) } ];
    return (wantarray) ? @$data : $data;
}

__PACKAGE__->meta->make_immutable;

1;
