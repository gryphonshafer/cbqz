package CBQZ::Model::Program;

use Moose;
use MooseX::ClassAttribute;

extends 'CBQZ::Model';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'Program' );

sub list {
    my ($self) = @_;
    my $programs = $self->rs->search;
    return ( $programs->count ) ? $programs : $self->create_default;
}

sub create_default {
    my ($self) = @_;
    my $rs = $self->rs->result_source->resultset;
    $rs->set_cache([ $self->rs->create({ name => 'Auto-created default' })->get_from_storage ]);
    return $rs;
}

__PACKAGE__->meta->make_immutable;

1;
