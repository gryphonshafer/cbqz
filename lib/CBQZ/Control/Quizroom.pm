package CBQZ::Control::Quizroom;

use exact;
use Mojo::Base 'Mojolicious::Controller';
use CBQZ::Model::Quiz;
use CBQZ::Model::Program;

sub index {
    my ($self) = @_;

    my $program = CBQZ::Model::Program->new->load( $self->cookie('cbqz_sets_program') );

    $self->stash(
        question_types => $program->types_list,
        timer_values   => $program->timer_values,
    );

    return;
}

sub path {
    my ($self) = @_;

    my $path             = $self->url_for->path('/quizroom');
    my $result_operation = CBQZ::Model::Program->new->load(
        $self->cookie('cbqz_sets_program')
    )->obj->result_operation;

    return $self->render(
        text => qq/
            var cntlr = "$path";
            function result_operation( result, as, number ) {
                $result_operation
                return { result: result, as: as, number: number };
            }
        /,
    );
}

sub data {
    my ($self) = @_;

    my $quiz = CBQZ::Model::Quiz->new->generate(
        $self->cookie('cbqz_sets_program'),
        $self->cookie('cbqz_sets_material'),
        $self->cookie('cbqz_sets_questions'),
    );

    my $program = CBQZ::Model::Program->new->load( $self->cookie('cbqz_sets_program') );

    if ( $quiz->{error} ) {
        $self->notice( $quiz->{error} );
        $self->flash( message => $quiz->{error} );
    }

    return $self->render( json => {
        metadata => {
            types         => CBQZ::Model::Program->new->load( $self->cookie('cbqz_sets_program') )->types_list,
            timer_default => $program->obj->timer_default,
            as_default    => $program->obj->as_default,
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
                $_->{marked} = undef;
                $_;
            } @{ $quiz->{questions} }
        ],
        question => {
            map { $_ => undef } qw( number type as used book chapter verse question answer marked )
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

sub mark {
    my ($self) = @_;
    my $json = $self->req_body_json;

    $self->dq->sql('UPDATE question SET marked = ? WHERE question_id = ?')
        ->run( $json->{reason}, $json->{question_id} );

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
