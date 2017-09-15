package CBQZ::Control::Quizroom;

use exact;
use Mojo::Base 'Mojolicious::Controller';
use CBQZ::Model::Quiz;

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

    my $quiz = CBQZ::Model::Quiz->new->generate;

    if ( $quiz->{error} ) {
        $self->notice( $quiz->{error} );
        $self->flash( message => $quiz->{error} );
    }

    return $self->render( json => {
        metadata => {
            types => [ qw( INT MA CR CVR MACR MACVR QT QTN FTV FT2V FT FTN SIT ) ],
        },
        material => {
            data           => $quiz->{material},
            search         => undef,
            matched_verses => undef,
            ( map { $_ => undef } map { $_, $_ . 's' } qw( book chapter verse ) ),
        },
        questions => [
            map {
                $_->{number} = undef;
                $_->{as}     = undef;
                $_;
            } @{ $quiz->{questions} }
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

    $self->dq->sql('UPDATE question SET used = used + 1 WHERE question_id = ?')->run( $json->{question_id} );
    return $self->render( json => {} );
}

sub replace {
    my ($self) = @_;
    my $json = $self->req_body_json;

    my $refs = join( ', ',
        map { $self->dq->quote($_) }
        'invalid reference',
        ( map { $_->{book} . ' ' . $_->{chapter} . ':' . $_->{verse} } @{ $json->{questions} } )
    );

    my $results = $self->dq->sql(qq{
        SELECT question_id, book, chapter, verse, question, answer, type, used
        FROM question
        WHERE
            type = ? AND
            CONCAT( book, ' ', chapter, ':', verse ) NOT IN ($refs)
        ORDER BY used, RAND()
        LIMIT 1
    })->run( $json->{type} )->all({});

    unless (@$results) {
        my $ids = join( ', ', 0, map { $_->{question_id} } @{ $json->{questions} } );

        $results = $self->dq->sql(qq{
            SELECT question_id, book, chapter, verse, question, answer, type, used
            FROM question
            WHERE
                type = ? AND
                question_id NOT IN ($ids)
            ORDER BY used, RAND()
            LIMIT 1
        })->run( $json->{type} )->all({});
    }

    return $self->render( json => {
        question => (@$results) ? $results->[0] : undef,
        error    => (@$results) ? undef : 'Failed to find question of that type.',
    } );
}

1;
