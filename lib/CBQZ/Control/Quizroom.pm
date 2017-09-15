package CBQZ::Control::Quizroom;

use exact;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my ($self) = @_;

    my $question_set_id = $self->dq->sql(q{
        SELECT question_set_id
        FROM question_set
        WHERE user_id = ?
        ORDER BY last_modified DESC, created DESC
        LIMIT 1
    })->run( $self->session('user_id') )->value;

    unless ($question_set_id) {
        $self->dq->sql(q{
            INSERT INTO question_set ( user_id, name ) VALUES ( ?, ? )
        })->run(
            $self->session('user_id'),
            $self->stash('user')->obj->name . ' auto-created',
        );
        $question_set_id = $self->dq->sql('SELECT last_insert_id()')->run->value;
    }

    $self->session( 'question_set_id' => $question_set_id );
    return;
}

sub path {
    my ($self) = @_;
    return $self->render( text => 'var cntlr = "' . $self->url_for->path('/quizroom') . '";' );
}

sub data {
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
            })->run(1)->all({})
        }
    );

    my @question_types = (
        [ ['INT'],                     [ 8, 12 ] ],
        [ [ qw( MA MACR MACVR ) ],     [ 2,  7 ] ],
        [ [ qw( CR CVR MACR MACVR ) ], [ 3,  5 ] ],
        [ [ qw( QT QTN ) ],            [ 1,  2 ] ],
        [ [ qw( FTV FT2V FT FTN ) ],   [ 1,  2 ] ],
        [ ['SIT'],                     [ 0,  4 ] ],
    );
    my $target_questions_count = 50;

    my @questions;
    for my $question_type (@question_types) {

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
            LIMIT $min
        })->run->all({});

        if ( @$results < $min ) {
            my $sub_min = $min - @$results;
            my $ids_sql = join( ', ', map { $_->{question_id} } @questions, @$results );

            push( @$results, @{ $self->dq->sql(qq{
                SELECT question_id, book, chapter, verse, question, answer, type, used
                FROM question
                WHERE
                    type IN ($types) AND
                    question_id NOT IN ($ids_sql)
                ORDER BY used, RAND()
                LIMIT $sub_min
            })->run->all({}) } );
        }

        die if ( @$results < $min );
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
            my $ids_sql = join( ', ', map { $_->{question_id} } @questions, @$results );

            push( @$results, @{ $self->dq->sql(qq{
                SELECT question_id, book, chapter, verse, question, answer, type, used
                FROM question
                WHERE
                    type IN ($types) AND
                    question_id NOT IN ($ids_sql)
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
            $limit      = $target_questions_count - @questions;
            my $ids_sql = join( ', ', map { $_->{question_id} } @questions );

            push( @questions, @{ $self->dq->sql(qq{
                SELECT question_id, book, chapter, verse, question, answer, type, used
                FROM question
                WHERE question_id NOT IN ($ids_sql)
                ORDER BY used, RAND()
                LIMIT $limit
            })->run->all({}) } );
        }
    }

    if ( @questions < $target_questions_count ) {
        $self->notice('Failed to create a question set in quizroom data build');
        $self->flash( message => 'Failed to create a full question set for this quiz.' );
    }

    return $self->render( json => {
        metadata => {
            types => [ qw( INT MA CR CVR MACR MACVR QT QTN FTV FT2V FT FTN SIT ) ],
        },
        material => {
            data           => $material,
            search         => undef,
            matched_verses => undef,
            ( map { $_ => undef } map { $_, $_ . 's' } qw( book chapter verse ) ),
        },
        questions => [
            map {
                $_->{number} = undef;
                $_->{as}     = undef;
                $_;
            } @questions
        ],
        question => {
            map { $_ => undef } qw( number type as used book chapter verse question answer )
        },
        position => 0,
        timer    => {
            value => 30,
            state => 'ready',
            label => 'Start Timer',
        },
    } );
}

sub used {
    my ($self) = @_;
    my $json = $self->req_body_json;


$self->warn( $json->{question_id} );


    $self->dq->sql('UPDATE question SET used = used + 1 WHERE question_id = ?')->run( $json->{question_id} );
    return $self->render( json => {} );
}

1;
