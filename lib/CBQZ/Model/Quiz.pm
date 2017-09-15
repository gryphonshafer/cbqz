package CBQZ::Model::Quiz;

use Moose;
use Try::Tiny;

extends 'CBQZ';

sub generate {
    my ($self) = @_;

    my $material = {};
    try {
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
                })->run(1)->all({})
            }
        );
    };

    my @question_types = (
        [ ['INT'],                     [ 8, 12 ] ],
        [ [ qw( MA MACR MACVR ) ],     [ 2,  7 ] ],
        [ [ qw( CR CVR MACR MACVR ) ], [ 3,  5 ] ],
        [ [ qw( QT QTN ) ],            [ 1,  2 ] ],
        [ [ qw( FTV FT2V FT FTN ) ],   [ 1,  2 ] ],
        [ ['SIT'],                     [ 0,  4 ] ],
    );
    my $target_questions_count = 50;

    my ( @questions, $error );
    try {
        for my $question_type (@question_types) {
            my $types = join( ', ', map { $self->dq->quote($_) } @{ $question_type->[0] } );
            my $min   = $question_type->[1][0];
            my $refs  = (@questions)
                ? 'AND CONCAT( book, " ", chapter, ":", verse ) NOT IN (' . join( ', ',
                    map { $self->dq->quote($_) }
                    'invalid reference',
                    ( map { $_->{book} . ' ' . $_->{chapter} . ':' . $_->{verse} } @questions )
                ) . ')'
                : '';

            my $results = $self->dq->sql(qq{
                SELECT question_id, book, chapter, verse, question, answer, type, used
                FROM question
                WHERE type IN ($types) $refs
                ORDER BY used, RAND()
                LIMIT $min
            })->run->all({});

            if ( @$results < $min ) {
                my $sub_min = $min - @$results;
                my $ids = ( @questions or @$results )
                    ? 'AND question_id NOT IN (' . join( ', ',
                        map { $_->{question_id} } @questions, @$results
                    ) . ')'
                    : '';

                push( @$results, @{ $self->dq->sql(qq{
                    SELECT question_id, book, chapter, verse, question, answer, type, used
                    FROM question
                    WHERE type IN ($types) $ids
                    ORDER BY used, RAND()
                    LIMIT $sub_min
                })->run->all({}) } );
            }

            die 'Unable to meet quiz set minimum requirements' if ( @$results < $min );
            push( @questions, @$results );
        }

        @questions = map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [ $_, rand ] } @questions;

        @question_types =
            map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map { [ $_, rand() ] }
            map { ($_) x ( $_->[1][1] - $_->[1][0] ) } @question_types;

        while ( @questions < $target_questions_count and @question_types ) {
            my $question_type = shift @question_types;

            my $types = join( ', ', map { $self->dq->quote($_) } @{ $question_type->[0] } );
            my $min   = $question_type->[1][0];
            my $refs  = join( ', ',
                map { $self->dq->quote($_) }
                'invalid reference', ( map { $_->{book} . ' ' . $_->{chapter} . ':' . $_->{verse} } @questions )
            );

            my $results = $self->dq->sql(qq{
                SELECT question_id, book, chapter, verse, question, answer, type, used
                FROM question
                WHERE
                    type IN ($types) AND
                    CONCAT( book, ' ', chapter, ':', verse ) NOT IN ($refs)
                ORDER BY used, RAND()
                LIMIT 1
            })->run->all({});

            unless (@$results) {
                my $ids = join( ', ', map { $_->{question_id} } @questions, @$results );

                push( @$results, @{ $self->dq->sql(qq{
                    SELECT question_id, book, chapter, verse, question, answer, type, used
                    FROM question
                    WHERE
                        type IN ($types) AND
                        question_id NOT IN ($ids)
                    ORDER BY used, RAND()
                    LIMIT 1
                })->run->all({}) } );
            }

            push( @questions, @$results );
        }

        if ( @questions < $target_questions_count ) {
            my $limit = $target_questions_count - @questions;
            my $refs  = join( ', ',
                map { $self->dq->quote($_) }
                'invalid reference', ( map { $_->{book} . ' ' . $_->{chapter} . ':' . $_->{verse} } @questions )
            );

            push( @questions, @{ $self->dq->sql(qq{
                SELECT question_id, book, chapter, verse, question, answer, type, used
                FROM question
                WHERE CONCAT( book, ' ', chapter, ':', verse ) NOT IN ($refs)
                ORDER BY used, RAND()
                LIMIT $limit
            })->run->all({}) } );

            if ( @questions < $target_questions_count ) {
                $limit  = $target_questions_count - @questions;
                my $ids = join( ', ', map { $_->{question_id} } @questions );

                push( @questions, @{ $self->dq->sql(qq{
                    SELECT question_id, book, chapter, verse, question, answer, type, used
                    FROM question
                    WHERE question_id NOT IN ($ids)
                    ORDER BY used, RAND()
                    LIMIT $limit
                })->run->all({}) } );
            }
        }

        die 'Failed to create a question set to target size' if ( @questions < $target_questions_count );
    }
    catch {
        $error = $self->clean_error($_);
    };

    return {
        material  => $material,
        questions => \@questions,
        error     => $error,
    };
}

__PACKAGE__->meta->make_immutable;

1;
