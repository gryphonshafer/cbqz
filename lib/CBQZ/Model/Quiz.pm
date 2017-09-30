package CBQZ::Model::Quiz;

use Moose;
use Try::Tiny;
use CBQZ::Model::Program;

extends 'CBQZ';

sub generate {
    my ( $self, $program_id, $material_set_id, $question_set_id ) = @_;

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
                })->run($material_set_id)->all({})
            }
        );
    };

    my $program                = CBQZ::Model::Program->new->load($program_id);
    my @question_types         = @{ $self->json->decode( $program->obj->question_types ) };
    my $target_questions_count = $program->obj->target_questions;

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
                WHERE type IN ($types) $refs AND marked IS NULL
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
                    WHERE type IN ($types) $ids AND marked IS NULL
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
                    CONCAT( book, ' ', chapter, ':', verse ) NOT IN ($refs) AND
                    marked IS NULL
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
                        question_id NOT IN ($ids) AND
                        marked IS NULL
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
                WHERE CONCAT( book, ' ', chapter, ':', verse ) NOT IN ($refs) AND marked IS NULL
                ORDER BY used, RAND()
                LIMIT $limit
            })->run->all({}) } );

            if ( @questions < $target_questions_count ) {
                $limit  = $target_questions_count - @questions;
                my $ids = join( ', ', map { $_->{question_id} } @questions );

                push( @questions, @{ $self->dq->sql(qq{
                    SELECT question_id, book, chapter, verse, question, answer, type, used
                    FROM question
                    WHERE question_id NOT IN ($ids) AND marked IS NULL
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
