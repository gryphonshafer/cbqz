package CBQZ::Model::QuestionSet;

use Moose;
use MooseX::ClassAttribute;
use exact;

extends 'CBQZ::Model';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'QuestionSet' );

has 'statistics' => ( isa => 'ArrayRef[HashRef]', is => 'rw', lazy => 1, default => sub {
    return shift->generate_statistics;
} );

sub create ( $self, $user, $name = undef ){
    $name //= 'Default ' . ucfirst( $user->obj->name ) . ' Set';

    $self->obj(
        $self->rs->create({
            user_id => $user->obj->id,
            name    => $name,
        })->get_from_storage
    );

    return $self;
}

sub get_questions ($self) {
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

sub generate_statistics ($self) {
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

sub data ($self) {
    my $data = $self->SUPER::data;
    $data->{statistics} = $self->statistics;
    return $data;
}

sub is_owned_by ( $self, $user ) {
    return (
        $user->obj->id and $self->obj->user_id and
        $user->obj->id == $self->obj->user_id
    ) ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;

1;
