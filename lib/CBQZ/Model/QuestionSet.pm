package CBQZ::Model::QuestionSet;

use Moose;
use MooseX::ClassAttribute;
use exact;
use Try::Tiny;
use CBQZ::Model::Question;

extends 'CBQZ::Model';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'QuestionSet' );

has 'statistics' => ( isa => 'ArrayRef[HashRef]', is => 'rw', lazy => 1, default => sub {
    return shift->generate_statistics;
} );

sub create ( $self, $user, $name = undef ) {
    $name //= 'Default ' . ucfirst( $user->obj->realname || $user->obj->username ) . ' Set';

    $self->obj(
        $self->rs->create({
            user_id => $user->obj->id,
            name    => $name,
        })->get_from_storage
    );

    $user->event('create_question_set');
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
                COUNT(*) AS questions,
                SUM( IF( marked IS NOT NULL, 1, 0 ) ) AS marked
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
            $user->obj->user_question_sets->search({ type => 'share' })->all
    ) ? 1 : 0;
}

sub clone ( $self, $user, $new_set_name ) {
    E->throw('User not authorized to clone this question set') unless (
        $self->is_owned_by($user) or
        grep { $_->question_set_id == $self->obj->id }
            $user->obj->user_question_sets->search({ type => 'publish' })->all
    );

    my $new_set = $self->rs->create({
        user_id => $user->obj->id,
        name    => $new_set_name,
    });

    $self->dq->sql(q{
        INSERT INTO question (
            question_set_id,
            book, chapter, verse, question, answer, type, used, marked, score
        )
        SELECT
            ?,
            book, chapter, verse, question, answer, type, used, marked, score
        FROM question WHERE question_set_id = ?
    })->run( $new_set->id, $self->obj->id );

    $user->event('clone_question_set');

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

    my @preexisting_user_ids = map { @$_ } @{
        $self->dq->sql('SELECT user_id FROM user_question_set WHERE question_set_id = ? AND type = ?')
            ->run( $self->obj->id, $type )->all
    };

    my @new_user_ids = grep { defined } map {
        my $selected_user_id = $_;
        ( grep { $_ == $selected_user_id } @preexisting_user_ids ) ? undef : $selected_user_id;
    } @$selected_user_ids;

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

    $user->event('save_set_select_users');

    return \@new_user_ids;
}

sub import_questions ( $self, $questions, $material_set ) {
    $self->fork( sub {
        for my $question_data (@$questions) {
            $question_data->{type} = 'MACR'  if ( $question_data->{type} eq 'CRMA'  );
            $question_data->{type} = 'MACVR' if ( $question_data->{type} eq 'CVRMA' );
            $question_data->{type} = 'Q'     if ( $question_data->{type} eq 'QT'    );

            $question_data->{verse} =~ s/\D.*$//g;

            $question_data->{question} =~ s/^\s+|\s+$//g;
            $question_data->{answer}   =~ s/^\s+|\s+$//g;

            $question_data->{question} =~ s/^Q:\s+//i;
            $question_data->{answer}   =~ s/^A:\s+//i;

            $question_data->{question_set_id} = $self->obj->id;

            my $question_obj = CBQZ::Model::Question->new->create($question_data);

            my $data = $question_obj->auto_text($material_set);
            $data->{marked} = delete $data->{error} if ( $data->{error} );

            $question_obj->obj->update($data);
            $question_obj->calculate_score($material_set);
        }
    } );

    return $self;
}

sub merge ( $self, $question_set_ids, $user = undef ) {
    E->throw('Did not receive an arrayref of >1 question set IDs to merge')
        unless ( ref $question_set_ids eq 'ARRAY' and @$question_set_ids > 1 );

    my @question_sets = map { $self->new->load($_) } @$question_set_ids;
    @question_sets = grep { $_->is_usable_by($user) } @question_sets if ($user);

    my $new_set = $self->rs->create({
        user_id => $user->obj->id,
        name    => 'Merged Question Set ' . scalar( localtime() ),
    });

    $self->dq->sql(q{
        INSERT INTO question (
            question_set_id,
            book, chapter, verse, question, answer, type, used, marked, score
        )
        SELECT
            ?,
            book, chapter, verse, question, answer, type, used, marked, score
        FROM question WHERE question_set_id = ?
    })->run( $new_set->id, $_->obj->id ) for (@question_sets);

    $user->event('merge_question_sets');

    return $new_set;
}

sub auto_kvl ( $self, $material_set, $user = undef ) {
    E->throw('User does not have permission to auto-KVL this set')
        if ( $user and not $self->is_usable_by($user) );

    $self->fork( sub {
        my $question_model = CBQZ::Model::Question->new;
        for my $type (
            [ 'Q',   'solo',  [ undef, 'Q', 'FT'    ] ],
            [ 'FTV', 'solo',  [ undef, 'FTV'        ] ],
            [ 'Q2V', 'range', [ undef, 'Q2V', 'FTN' ] ],
            [ 'F2V', 'range', [ undef, 'F2V'        ] ],
            [ 'FT',  'solo',  'FT'  ],
            [ 'FTN', 'range', 'FTN' ],
        ) {
            my $verses = $material_set->obj->materials->search(
                {
                    key_class => $type->[1],
                    key_type  => $type->[2],
                },
                {
                    order_by => [ qw( book chapter verse ) ],
                },
            );

            my $in_range = 0;
            while ( my $verse = $verses->next ) {
                if ( $type->[1] eq 'range' ) {
                    if ($in_range) {
                        $in_range = 0;
                        next;
                    }
                    else {
                        $in_range = 1;
                    }
                }

                $question_model->new->create({
                    question_set_id => $self->obj->id,
                    %{ $question_model->auto_text( $material_set, {
                        book    => $verse->book,
                        chapter => $verse->chapter,
                        verse   => $verse->verse,
                        type    => $type->[0],
                    } ) },
                })->calculate_score($material_set);
            }
        }
    } );

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
