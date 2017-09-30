package CBQZ::Model::MaterialSet;

use Moose;
use MooseX::ClassAttribute;

extends 'CBQZ::Model';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'MaterialSet' );

sub list {
    my ($self) = @_;
    return $self->rs->search;
}

sub get_material {
    my ($self) = @_;

    my $material = {};
    $material->{ $_->{book} }{ $_->{chapter} }{ $_->{verse} } = $_ for (
        map {
            ( $_->{search} = lc( $_->{text} ) ) =~ s/<[^>]+>//g;
            $_->{search} =~ s/\W//g;
            $_;
        }
        @{
            $self->dq->sql(q{
                SELECT book, chapter, verse, text, key_class, key_type, is_new_para
                FROM material
                WHERE material_set_id = ?
            })->run( $self->obj->id )->all({})
        }
    );

    return $material;
}

__PACKAGE__->meta->make_immutable;

1;
