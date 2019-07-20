package CBQZ::Model::MaterialSet;

use Moose;
use MooseX::ClassAttribute;
use exact;

extends 'CBQZ::Model';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'MaterialSet' );

has material => ( isa => 'ArrayRef[HashRef]', is => 'rw' );

sub get_material ( $self, $as = {} ) {
    $self->load_material unless ( $self->material );
    return $self->material if ( ref $as eq 'ARRAY' );

    my $material = {};
    $material->{ $_->{book} }{ $_->{chapter} }{ $_->{verse} } = $_ for ( @{ $self->material } );
    return $material;
}

sub load_material ($self) {
    $self->material(
        $self->dq->sql(q{
            SELECT book, chapter, verse, text, key_class, key_type, is_new_para
            FROM material
            WHERE material_set_id = ?
        })->run( $self->obj->id )->all({})
    );

    return $self;
}

sub get_books ($self) {
    return unless ( $self->obj );
    my $book_order = $self->obj->book_order;
    return ($book_order) ? $self->json->decode($book_order) : undef;
}

__PACKAGE__->meta->make_immutable;

1;
