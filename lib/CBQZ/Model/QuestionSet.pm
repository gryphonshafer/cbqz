package CBQZ::Model::QuestionSet;

use Moose;
use MooseX::ClassAttribute;

extends 'CBQZ::Model';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'QuestionSet' );

sub create_default {
    my ( $self, $user ) = @_;
    my $rs = $self->rs->result_source->resultset;

    $rs->set_cache([ $self->rs->create({
        user_id => $user->id,
        name    => 'Default ' . ucfirst( $user->obj->name ) . ' Set',
    })->get_from_storage ]);

    return $rs;
}

sub get_questions {
    my ($self) = @_;

    my $questions = {};
    $questions->{ $_->{book} }{ $_->{chapter} }{ $_->{question_id} } = $_ for (
        @{
            $self->dq->sql(q{
                SELECT question_id, book, chapter, verse, question, answer, type, used, marked
                FROM question
                WHERE question_set_id = ?
            })->run( $self->obj->id )->all({})
        }
    );

    return $questions;
}

__PACKAGE__->meta->make_immutable;

1;
