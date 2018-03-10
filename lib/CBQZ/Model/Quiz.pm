package CBQZ::Model::Quiz;

use Moose;
use MooseX::ClassAttribute;
use exact;
use Try::Tiny;
use CBQZ::Model::Program;

extends 'CBQZ::Model';

class_has 'schema_name' => ( isa => 'Str', is => 'ro', default => 'Quiz' );

sub create ( $self, $config ){

    # TODO: generate "questions" data -> into metadata

    $self->obj(
        $self->rs->create({
            metadata => $self->json->encode( {
                timer_values => $self->json->encode( [
                    map { 0 + $_ } grep { /^\d+$/ } split( /\D+/, $config->{timer_values} )
                ] ),
                map { $_ => $config->{$_} } qw( target_questions timer_default quiz_teams_quizzers )
            }),
            official => ( ( $config->{official} ) ? 1 : 0 ),
            map { $_ => $config->{$_} } qw( program_id user_id name quizmaster room scheduled )
        } )->get_from_storage
    );

    return $self;
}

sub quizzes_for_user ( $self, $user, $program ) {
    return [
        map { +{ $_->get_inflated_columns } }
        $self->rs->search(
            {
                user_id    => $user->obj->id,
                program_id => $program->obj->id,
                state      => [ qw( pending active ) ],
            },
            {
                order_by => { -desc => [ qw( official scheduled room ) ] },
            },
        )->all
    ];
}

sub chapter_set ( $self, $cbqz_prefs ) {
    my @chapter_set_prime = map { $_->{book} . ' ' . $_->{chapter} } @{ $cbqz_prefs->{selected_chapters} };
    my @chapter_set_weight;
    push( @chapter_set_weight, pop @chapter_set_prime )
        while ( @chapter_set_weight < $cbqz_prefs->{weight_chapters} );

    return {
        prime  => join( ', ', map { $self->dq->quote($_) } @chapter_set_prime ),
        weight => join( ', ', map { $self->dq->quote($_) } @chapter_set_weight ),
    };
}

sub generate ( $self, $cbqz_prefs ) {

    # TODO: generate quiz based on quiz row data...

    my $chapter_set            = $self->chapter_set($cbqz_prefs);
    my $program                = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );
    my $target_questions_count = $program->obj->target_questions;
    my @question_types         =
        map {
            my ( $label, $min, $max, @types ) = split(/\W+/);
            [ \@types, [ $min, $max ], $label ];
        }
        grep { /^\W*\w+\W+\w+\W+\w+\W+\w+/ }
        split( /\r?\n/, $cbqz_prefs->{question_types} );

    my ( @questions, $error );
    try {
        E->throw('No chapters selected from which to build a quiz; select chapters and retry')
            unless ( length $chapter_set->{prime} or length $chapter_set->{weight} );

        # select the minimum questions for each question type
        for my $question_type (@question_types) {
            my $types = join( ', ', map { $self->dq->quote($_) } @{ $question_type->[0] } );
            my $min   = $question_type->[1][0];

            my %min;
            $min{prime} = ( $cbqz_prefs->{weight_percent} and $cbqz_prefs->{weight_chapters} )
                ? int( $min * ( 1 - $cbqz_prefs->{weight_percent} / 100 ) )
                : $min;
            $min{weight} = $min - $min{prime};

            my @pending_questions;
            for my $selection ( qw( prime weight ) ) {
                my $selection_set = $chapter_set->{$selection};
                next unless ($selection_set);

                my $refs = (@questions)
                    ? 'AND CONCAT( book, " ", chapter, ":", verse ) NOT IN (' . join( ', ',
                        map { $self->dq->quote($_) }
                        'invalid reference',
                        ( map { $_->{book} . ' ' . $_->{chapter} . ':' . $_->{verse} } @questions )
                    ) . ')'
                    : '';

                my $results = $self->dq->sql(qq{
                    SELECT question_id, book, chapter, verse, question, answer, type, used, score
                    FROM question
                    WHERE
                        type IN ($types) $refs AND marked IS NULL AND question_set_id = ? AND
                        CONCAT( book, " ", chapter ) IN ($selection_set)
                    ORDER BY used, RAND()
                    LIMIT $min{$selection}
                })->run( $cbqz_prefs->{question_set_id} )->all({});

                if ( @$results < $min{$selection} ) {
                    my $sub_min = $min{$selection} - @$results;
                    my $ids = ( @questions or @$results )
                        ? 'AND question_id NOT IN (' . join( ', ',
                            map { $_->{question_id} } @questions, @$results
                        ) . ')'
                        : '';

                    push( @$results, @{ $self->dq->sql(qq{
                        SELECT question_id, book, chapter, verse, question, answer, type, used, score
                        FROM question
                        WHERE
                            type IN ($types) $ids AND marked IS NULL AND question_set_id = ? AND
                            CONCAT( book, " ", chapter ) IN ($selection_set)
                        ORDER BY used, RAND()
                        LIMIT $sub_min
                    })->run( $cbqz_prefs->{question_set_id} )->all({}) } );
                }

                push( @pending_questions, @$results );
            }

            E->throw('Unable to meet quiz set minimum requirements') if ( @pending_questions < $min );
            push( @questions, @pending_questions );
        }

        # randomly sort the minimum questions set
        @questions = map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [ $_, rand ] } @questions;

        # pseudo-randomize question types not yet at max based on reaching max as late as possible
        @question_types =
            sort { $b->[3] <=> $a->[3] }
            map {
                my $type = $_;
                map { [ @$type, $_ + rand() ] } 0 .. ( $_->[1][1] - $_->[1][0] );
            }
            grep { $_->[1][1] - $_->[1][0] > 0 }
            @question_types;

        # append additional questions based on question type order up to target count
        while ( @questions < $target_questions_count and @question_types ) {
            my $question_type = shift @question_types;

            my $types = join( ', ', map { $self->dq->quote($_) } @{ $question_type->[0] } );
            my $min   = $question_type->[1][0];
            my $refs  = join( ', ',
                map { $self->dq->quote($_) }
                'invalid reference', ( map { $_->{book} . ' ' . $_->{chapter} . ':' . $_->{verse} } @questions )
            );
            my $selection_set = $chapter_set->{
                ( $cbqz_prefs->{weight_percent} >= rand() * 100 ) ? 'weight' : 'prime'
            };
            next unless ($selection_set);

            my $results = $self->dq->sql(qq{
                SELECT question_id, book, chapter, verse, question, answer, type, used, score
                FROM question
                WHERE
                    type IN ($types) AND
                    CONCAT( book, ' ', chapter, ':', verse ) NOT IN ($refs) AND
                    marked IS NULL AND
                    question_set_id = ? AND
                    CONCAT( book, " ", chapter ) IN ($selection_set)
                ORDER BY used, RAND()
                LIMIT 1
            })->run( $cbqz_prefs->{question_set_id} )->all({});

            unless (@$results) {
                my $ids = join( ', ', map { $_->{question_id} } @questions, @$results );

                push( @$results, @{ $self->dq->sql(qq{
                    SELECT question_id, book, chapter, verse, question, answer, type, used, score
                    FROM question
                    WHERE
                        type IN ($types) AND
                        question_id NOT IN ($ids) AND
                        marked IS NULL AND
                        question_set_id = ? AND
                        CONCAT( book, " ", chapter ) IN ($selection_set)
                    ORDER BY used, RAND()
                    LIMIT 1
                })->run( $cbqz_prefs->{question_set_id} )->all({}) } );
            }

            push( @questions, @$results );
        }

        # append additional questions up to target count
        while ( @questions < $target_questions_count ) {
            my $selection_set = $chapter_set->{
                ( $cbqz_prefs->{weight_percent} >= rand() * 100 ) ? 'weight' : 'prime'
            };
            next unless ($selection_set);

            my $refs = join( ', ',
                map { $self->dq->quote($_) }
                'invalid reference', ( map { $_->{book} . ' ' . $_->{chapter} . ':' . $_->{verse} } @questions )
            );

            my ($question) = @{ $self->dq->sql(qq{
                SELECT question_id, book, chapter, verse, question, answer, type, used, score
                FROM question
                WHERE
                    CONCAT( book, ' ', chapter, ':', verse ) NOT IN ($refs) AND
                    marked IS NULL AND
                    question_set_id = ? AND
                    CONCAT( book, " ", chapter ) IN ($selection_set)
                ORDER BY used, RAND()
                LIMIT 1
            })->run( $cbqz_prefs->{question_set_id} )->all({}) };

            last unless ($question);
            push( @questions, $question );
        }

        while ( @questions < $target_questions_count ) {
            my $selection_set = $chapter_set->{
                ( $cbqz_prefs->{weight_percent} >= rand() * 100 ) ? 'weight' : 'prime'
            };
            next unless ($selection_set);

            my $ids = join( ', ', map { $_->{question_id} } @questions );

            my ($question) = @{ $self->dq->sql(qq{
                SELECT question_id, book, chapter, verse, question, answer, type, used, score
                FROM question
                WHERE
                    question_id NOT IN ($ids) AND marked IS NULL AND question_set_id = ? AND
                    CONCAT( book, " ", chapter ) IN ($selection_set)
                ORDER BY used, RAND()
                LIMIT 1
            })->run( $cbqz_prefs->{question_set_id} )->all({}) };

            last unless ($question);
            push( @questions, $question );
        }

        E->throw('Failed to create a question set to target size') if ( @questions < $target_questions_count );
    }
    catch {
        $error = $self->clean_error($_);
    };

    return {
        questions => \@questions,
        error     => $error,
    };
}

sub replace ( $self, $request, $cbqz_prefs ) {
    my $chapter_set = $self->chapter_set($cbqz_prefs);

    unless ( length $chapter_set->{prime} or length $chapter_set->{weight} ) {
        $self->warn("Replace question: No chapters selected from which to build a quiz");
        return [];
    }

    my $selection     = ( $cbqz_prefs->{weight_percent} >= rand() * 100 ) ? 'weight' : 'prime';
    my $selection_set = $chapter_set->{$selection};
    $selection_set    = $chapter_set->{ ( $selection eq 'prime' ) ? 'weight' : 'prime' } unless ($selection_set);

    my $refs = join( ', ',
        map { $self->dq->quote($_) }
        'invalid reference',
        ( map { $_->{book} . ' ' . $_->{chapter} . ':' . $_->{verse} } @{ $request->{questions} } )
    );

    my $results = $self->dq->sql(qq{
        SELECT question_id, book, chapter, verse, question, answer, type, used, score
        FROM question
        WHERE
            question_set_id = ? AND type = ? AND marked IS NULL AND
            CONCAT( book, " ", chapter ) IN ($selection_set) AND
            CONCAT( book, ' ', chapter, ':', verse ) NOT IN ($refs)
        ORDER BY used, RAND()
        LIMIT 1
    })->run( $cbqz_prefs->{question_set_id}, $request->{type} )->all({});

    unless (@$results) {
        my $ids = join( ', ', 0, map { $_->{question_id} } @{ $request->{questions} } );

        $results = $self->dq->sql(qq{
            SELECT question_id, book, chapter, verse, question, answer, type, used, score
            FROM question
            WHERE
                question_set_id = ? AND type = ? AND marked IS NULL AND
                CONCAT( book, " ", chapter ) IN ($selection_set) AND
                question_id NOT IN ($ids)
            ORDER BY used, RAND()
            LIMIT 1
        })->run( $cbqz_prefs->{question_set_id}, $request->{type} )->all({});
    }

    return $results;
}

__PACKAGE__->meta->make_immutable;

1;
