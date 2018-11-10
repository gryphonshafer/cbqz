package CBQZ::Control::Stats;

use Mojo::Base 'Mojolicious::Controller';
use exact;
use MIME::Base64 'decode_base64';
use CBQZ::Model::Quiz;
use CBQZ::Model::QuizQuestion;

sub path ($self) {
    return $self->render( text => 'var cntlr = "' . $self->url_for('/stats') . '";' );
}

sub index ($self) {
    my $get_quiz_data = sub {
        return [
            map {
                if ( $_->{state} eq 'active' ) {
                    my $status = $self->cbqz->json->decode( $_->{status} || '{}' );
                    $_->{question_number} = $status->{question_number} || 1;
                }
                $_;
            }
            CBQZ::Model::Quiz->new->every_data(
                {
                    state      => $_[0],
                    program_id => $self->decode_cookie('cbqz_prefs')->{program_id},
                    -or        => [
                        user_id  => $self->stash('user')->obj->id,
                        official => 1,
                    ],
                },
                {
                    order_by => { -desc => 'last_modified' },
                },
            )
        ];
    };

    $self->stash(
        quizzes => {
            active => $get_quiz_data->('active'),
            closed => $get_quiz_data->('closed'),
        },
    );
}

sub quiz ($self) {
    my $quiz    = CBQZ::Model::Quiz->new;
    my $quizzes = $quiz->rs->search(
        {
            quiz_id => $self->param('id'),
            -or     => [
                user_id => $self->stash('user')->obj->id,
                -and    => [
                    official   => 1,
                    program_id => [
                        map { $_->program->id } $self->stash('user')->obj->user_programs->all
                    ],
                ],
            ],
        }
    );

    unless ( $quizzes->count ) {
        $self->flash( message =>
            q{It appears you do not have access to view this particular quiz's data.}
        );
        return $self->redirect_to('/stats');
    }

    $quiz->obj( $quizzes->first );

    my $quiz_data = $quiz->data;
    $quiz_data->{$_} = $self->cbqz->json->decode( $quiz_data->{$_} ) for ( qw( metadata questions ) );

    $self->stash(
        quiz   => $quiz_data,
        events => [
            CBQZ::Model::QuizQuestion->new->every_data(
                { quiz_id => $quiz->obj->id },
                { order_by => 'created' },
            )
        ],
    );
}

sub delete_practice_quiz ($self) {
    CBQZ::Model::Quiz->new->rs->search({
        quiz_id  => [ keys %{ $self->params } ],
        official => 0,
        user_id  => $self->stash('user')->obj->id,
    })->delete;

    return $self->redirect_to('/stats');
}

sub delete_official_quiz ($self) {
    CBQZ::Model::Quiz->new->rs->search({
        quiz_id    => $self->param('quiz_id'),
        program_id => $self->decode_cookie('cbqz_prefs')->{program_id},
    })->delete if ( $self->stash('user')->has_role('director') );

    return $self->redirect_to('/stats');
}

sub live_scoresheet ($self) {
    return $self->redirect_to('/stats') unless ( $self->tx->is_websocket );
    $self->inactivity_timeout( $self->cbqz->config->get( qw( session duration ) ) );

    my $socket_name = join( '|',
        'live_scoresheet',
        $self->param('room'),
        $self->decode_cookie('cbqz_prefs')->{program_id},
    );

    $self->socket( setup => $socket_name, {
        tx => $self->tx,
        cb => sub ( $tx, $data ) {
            $tx->send( { json => $self->cbqz->json->decode($data) } );
        },
    });

    $self->on( finish => sub { $self->socket( finish => $socket_name, { tx => $self->tx } ) } );
}

sub meet_status ($self) {
    unless ( $self->tx->is_websocket ) {
        $self->render( json =>
            CBQZ::Model::Quiz->new->meet_status_quizzes(
                $self->decode_cookie('cbqz_prefs')->{program_id},
            ),
        );
    }
    else {
        $self->inactivity_timeout( $self->cbqz->config->get( qw( session duration ) ) );

        my $socket_name = join( '|',
            'meet_status',
            $self->decode_cookie('cbqz_prefs')->{program_id},
        );

        $self->socket( setup => $socket_name, {
            tx => $self->tx,
            cb => sub ( $tx, $data ) {
                $tx->send( { json => $self->cbqz->json->decode($data) } );
            },
        });

        $self->on( finish => sub { $self->socket( finish => $socket_name, { tx => $self->tx } ) } );
    }
}

sub quiz_edit ($self) {
    my $command = $self->cbqz->json->decode( decode_base64( $self->param('command') ) );

    if ( $self->stash('user')->has_role('director') ) {
        CBQZ::Model::Quiz->new->load( $command->{quiz_id} )
            ->obj->update({ $command->{name} => $command->{value} });

        $self->flash( message => {
            type => 'success',
            text => 'Quiz ' . $command->{name} . ' successfully edited.',
        } );
    }
    else {
        $self->flash( message => 'It appears you do not have necessary privilages to edit quizzes.' );
    }

    return $self->redirect_to( '/stats/quiz?id=' . $command->{quiz_id} );
}

1;
