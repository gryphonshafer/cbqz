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
    $name //= 'Default ' . ucfirst( $user->obj->realname || $user->obj->username ) . ' Set';

    $self->obj(
        $self->rs->create({
            user_id => $user->obj->id,
            name    => $name,
        })->get_from_storage
    );

    return $self;
}

sub get_questions ( $self, $as = {} ) {
    my $questions_data = $self->dq->sql(q{
        SELECT question_id, book, chapter, verse, question, answer, type, used, marked, score
        FROM question
        WHERE question_set_id = ?
    })->run( $self->obj->id )->all({});

    return $questions_data if ( ref $as eq 'ARRAY' );

    my $questions = {};
    $questions->{ $_->{book} }{ $_->{chapter} }{ $_->{question_id} } = $_ for (@$questions_data);
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

sub is_usable_by ( $self, $user ) {
    return (
        $self->is_owned_by($user) or
        grep { $_->question_set_id == $self->obj->id }
            $user->obj->user_question_sets->search({ type => 'Share' })->all
    ) ? 1 : 0;
}

sub clone ( $self, $user, $new_set_name, $fork = 0 ) {
    E->throw('User not authorized to clone this question set') unless (
        $self->is_owned_by($user) or
        grep { $_->question_set_id == $self->obj->id }
            $user->obj->user_question_sets->search({ type => 'Publish' })->all
    );

    my $new_set = $self->rs->create({
        user_id => $user->obj->id,
        name    => $new_set_name,
    });

    my $questions = $self->obj->questions;

    my $code = sub {
        while ( my $question = $questions->next ) {
            my $question_data = { $question->get_inflated_columns };
            delete $question_data->{question_id};
            $question_data->{question_set_id} = $new_set->id;
            $self->rs('Question')->create($question_data);
        }
    };

    if ($fork) {
        $self->fork($code);
    }
    else {
        $code->();
    }

    return $new_set;
}

sub users_to_select ( $self, $user, $type ) {
    return [
        sort { $a->{username} cmp $b->{username} }
        @{
            $self->dq->sql(q{
                SELECT
                    u.user_id AS id, u.username, u.realname,
                    SUM( IF( uqs.question_set_id = ? AND uqs.type = ?, 1, 0 ) ) AS checked
                FROM user_program AS up
                JOIN user AS u USING (user_id)
                LEFT OUTER JOIN user_question_set AS uqs USING (user_id)
                WHERE
                    up.program_id IN (
                       SELECT program_id FROM user_program WHERE user_id = ?
                    )
                    AND u.user_id != ?
                GROUP BY 1

            })->run(
                $self->obj->id,
                $type,
                ( $user->obj->id ) x 2,
            )->all({})
        }
    ];
}

sub save_set_select_users ( $self, $user, $type, $selected_user_ids ) {
    E->throw('User not authorized to save select users on this set')
        unless ( $self and $self->is_owned_by($user) );

    $self->dq->sql('DELETE FROM user_question_set WHERE question_set_id = ? AND type = ?')
        ->run( $self->obj->id, $type );

    my $insert = $self->dq->sql(q{
        INSERT INTO user_question_set ( question_set_id, user_id, type ) VALUES ( ?, ?, ? )
    });

    $insert->run(
        $self->obj->id,
        $_,
        $type,
    ) for (@$selected_user_ids);

    return;
}

__PACKAGE__->meta->make_immutable;

1;
