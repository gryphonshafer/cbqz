package CBQZ::Model::QuestionSet;

use Moose;
use MooseX::ClassAttribute;

extends 'CBQZ::Model';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'QuestionSet' );

has 'statistics' => ( isa => 'ArrayRef[HashRef]', is => 'rw', lazy => 1, default => sub {
    return shift->generate_statistics;
} );

sub create_default {
    my ( $self, $user ) = @_;
    my $rs = $self->rs->result_source->resultset;

    $rs->set_cache([ $self->rs->create({
        user_id => $user->obj->id,
        name    => 'Default ' . ucfirst( $user->obj->name ) . ' Set',
    })->get_from_storage ]);

    $self->obj($rs);
    return $self;
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

sub generate_statistics {
    my ($self) = @_;

    my %types;
    my $type_data;
    for (
        @{ $self->dq->sql(q{
            SELECT book, chapter, type, COUNT(*) AS questions
            FROM question
            WHERE question_set_id = ?
            GROUP BY book, chapter, type
        })->run( $self->obj->id )->all({}) }
    ) {
        $types{ $_->{type} } = 1;
        $type_data->{ $_->{book} }{ $_->{chapter} }{ $_->{type} } = $_->{questions};
    }

    my @types = sort keys %types;

    return [
        map {
            my $this_type_data = $type_data->{ $_->{book} }{ $_->{chapter} };
            $_->{types} = [ map { [ $_, $this_type_data->{$_} ] } @types ];
            $_;
        } @{ $self->dq->sql(q{
            SELECT
                book, chapter,
                COUNT( DISTINCT verse ) AS verses,
                COUNT(*) AS questions
            FROM question
            WHERE question_set_id = ?
            GROUP BY book, chapter
            ORDER BY book, chapter
        })->run( $self->obj->id )->all({}) }
    ];
}

sub to_data {
    my ($self) = @_;

    my $data = ( $self->obj ) ? { $self->obj->get_inflated_columns } : {};
    $data->{statistics} = $self->statistics;
    return $data;
}

__PACKAGE__->meta->make_immutable;

1;
