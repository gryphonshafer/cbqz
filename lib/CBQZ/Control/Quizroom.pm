package CBQZ::Control::Quizroom;

use Mojo::Base 'Mojolicious::Controller';
use exact;
use Try::Tiny;
use MIME::Base64 'encode_base64';
use Text::Unidecode 'unidecode';
use CBQZ::Model::Quiz;
use CBQZ::Model::Program;
use CBQZ::Model::MaterialSet;
use CBQZ::Model::Question;
use CBQZ::Model::QuizQuestion;
use CBQZ::Util::Format 'zulu_date_time';
use CBQZ::Util::File 'slurp';

sub index ($self) {
    return $self->stash( cntlr => $self->url_for('/quizroom') );
}

sub path ($self) {
    my $path = $self->url_for('/quizroom');
    my $text = qq/var cntlr = "$path";\n/;

    if ( $self->session('quiz_id') ) {
        my $result_operation = (
            ( $self->cbqz->config->get( 'program', 'force_default_result_operation' ) )
                ? CBQZ::Model::Program->new->default('result_operation')
                : CBQZ::Model::Quiz->new->load( $self->session('quiz_id') )->obj->result_operation
        ) || '';

        $text .= qq/
            function result_operation(input) {
                var output = {};
                $result_operation
                return output;
            }
        /;
    }

    return $self->render( text => $text );
}

{
    sub quiz_setup ($self) {
        my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');

        my @selected_chapters = map {
            $_->{book} . '|' . $_->{chapter}
        } @{ $cbqz_prefs->{selected_chapters} };

        my ($question_set) =
            grep { $cbqz_prefs->{question_set_id} == $_->{question_set_id} }
            ( map { +{ %{ $_->data }, share => 0 } } $self->stash('user')->question_sets ),
            ( map { +{ %{ $_->data }, share => 1 } } $self->stash('user')->shared_question_sets );

        for ( @{ $question_set->{statistics} } ) {
            my $id = $_->{book} . '|' . $_->{chapter};
            $_->{selected} = ( grep { $id eq $_ } @selected_chapters ) ? 1 : 0;
        }

        my $program = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );

        return $self->render( json => {
            weight_chapters     => $cbqz_prefs->{weight_chapters} // 0,
            weight_percent      => $cbqz_prefs->{weight_percent}  // 50,
            program_id          => $cbqz_prefs->{program_id}      || undef,
            question_set_id     => $cbqz_prefs->{question_set_id} || undef,
            material_set_id     => $cbqz_prefs->{material_set_id} || undef,
            question_set        => $question_set,
            scheduled           => zulu_date_time(),
            name                => zulu_date_time(),
            quizmaster          => $self->stash('user')->obj->realname,
            user_is_official    => $self->stash('user')->has_role('official'),
            target_questions    => $program->obj->target_questions,
            randomize_first     => $program->obj->randomize_first,
            timer_default       => $program->obj->timer_default,
            timeout             => $program->obj->timeout,
            timer_values        => join( ', ', @{ $self->cbqz->json->decode( $program->obj->timer_values ) } ),
            score_types         => $self->cbqz->json->decode( $program->obj->score_types ),
            readiness           => $program->obj->readiness,
            saved_quizzes       => [
                map {
                    if ( $_->{state} eq 'active' ) {
                        my $status = $self->cbqz->json->decode( $_->{status} || '{}' );
                        $_->{question_number} = $status->{question_number} || 1;
                    }
                    $_;
                }
                @{ CBQZ::Model::Quiz->new->quizzes_for_user( $self->stash('user'), $program ) },
            ],
            program_question_types => $program->question_types_as_text,
            book_order => CBQZ::Model::MaterialSet->new->load( $cbqz_prefs->{material_set_id} )->get_books,
        } );
    }
}

sub generate_quiz ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');
    my $quiz;

    my $success = try {
        E->throw('User is not a member of program ID set in CBQZ preferences cookie')
            unless ( $self->stash('user')->has_program_id( $cbqz_prefs->{program_id} ) );

        E->throw('User is not an official but has set the "official" flag for the quiz')
            if ( $self->req->param('official') and not $self->stash('user')->has_role('official') );

        my $set = CBQZ::Model::QuestionSet->new->load( $cbqz_prefs->{question_set_id} );
        E->throw('User does not own requested question set')
            unless ( $set and $set->is_usable_by( $self->stash('user') ) );

        my $program = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );

        $quiz = CBQZ::Model::Quiz->new->create({
            %$cbqz_prefs,
            %{ $self->params },
            user_id             => $self->stash('user')->obj->id,
            quiz_teams_quizzers => $self->req->param('quiz_teams_quizzers'),
            result_operation    => $program->obj->result_operation,
        });
    }
    catch {
        $self->warn( $self->cbqz->clean_error($_) );
        $self->flash( message =>
            'An error occurred while trying to generate the quiz: ' .
            $self->cbqz->clean_error($_) . '.'
        );

        (
            my $cbqz_quiz_form_values = encode_base64(
                $self->cbqz->json->encode({
                    map { $_ => $self->req->param($_) } qw(
                        name
                        quizmaster
                        scheduled
                        quiz_teams_quizzers
                    )
                })
            )
        ) =~ s/\r?\n//msg;
        $self->cookie( cbqz_quiz_form_values => $cbqz_quiz_form_values );

        $self->redirect_to('/quizroom');
        return undef;
    };
    return unless ($success);

    $self->stash('user')->event('generate_quiz');

    $self->flash( message => {
        type => 'success',
        text => 'Quiz "' . $self->req->param('name') . '" generated and saved for later.',
    } ) if ( $self->req->param('save_for_later') );

    return $self->redirect_to(
        ( $self->req->param('save_for_later') )
            ? '/quizroom'
            : '/quizroom/quiz?id=' . $quiz->obj->id
    );
}

sub quiz ($self) {
    $self->session( quiz_id => $self->req->param('id') );
    return;
}

sub data ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');
    my $quiz_id    = delete $self->session->{quiz_id} || $self->req->param('id');

    my $data = {
        metadata => {
            types         => [],
            timer_default => 0,
            timeout       => 0,
            readiness     => 0,
            as_default    => 'Error',
            type_ranges   => [],
        },
        material  => { Error => { 1 => { 1 => {
            book    => 'Error',
            chapter => 1,
            verse   => 1,
            text    =>
                'An error occurred while trying to load data. ' .
                'This is likely due to invalid quiz configuration settings.',
        } } } },
        questions => [],
    };

    try {
        my $program = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );

        E->throw('User does not have access to the quiz referenced by quiz ID') unless (
            grep { $_->{quiz_id} == $quiz_id } @{
                CBQZ::Model::Quiz->new->quizzes_for_user( $self->stash('user'), $program )
            }
        );

        my $set = CBQZ::Model::QuestionSet->new->load( $cbqz_prefs->{question_set_id} );
        E->throw('Question set in preferences noet usable by user')
            unless ( $set and $set->is_usable_by( $self->stash('user') ) );

        my $quiz     = CBQZ::Model::Quiz->new->load($quiz_id);
        my $metadata = $quiz->json->decode( $quiz->obj->metadata );

        $data->{questions} = $quiz->json->decode( unidecode( $quiz->obj->questions ) );
        $data->{metadata}  = {
            quiz_id     => $quiz_id,
            types       => $program->types_list,
            as_default  => $program->obj->as_default,
            type_ranges => $program->question_types_parse( $cbqz_prefs->{question_types} ),
            %$metadata,
        };
        $data->{quiz_questions} = [
            map {
                my $question = +{ $_->get_inflated_columns };
                delete $question->{question};
                $question;
            } $quiz->obj->quiz_questions->search( {}, { order_by => { -desc => 'created' } } )->all
        ];
        $data->{official}   = $quiz->obj->official;
        my $material_set    = CBQZ::Model::MaterialSet->new->load( $cbqz_prefs->{material_set_id} );
        $data->{material}   = $material_set->get_material;
        $data->{book_order} = $material_set->get_books;

        $quiz->obj->update({ state => 'active' });
        $quiz->obj->update({ quizmaster => $self->stash('user')->obj->realname })
            if ( $quiz->obj->quizmaster ne $self->stash('user')->obj->realname );
    }
    catch {
        $self->warn($_);
        $data->{error} =
            'An error occurred while trying to load data. ' .
            'This is likely due to invalid quiz configuration settings.';
    };

    return $self->render( json => $data );
}

my $quiz_data_ws = sub ( $self, $quiz, $cbqz_prefs ) {
    $self->socket(
        message => join( '|',
            'live_scoresheet',
            $quiz->obj->room,
            $cbqz_prefs->{program_id},
        ),
        { data => $self->cbqz->json->encode( $quiz->data_deep ) },
    ) if ( $quiz->obj->official );

    if ( my $meet_status_quizzes = $quiz->meet_status_quizzes( $cbqz_prefs->{program_id} ) ) {
        $self->socket(
            message => join( '|',
                'meet_status',
                $cbqz_prefs->{program_id},
            ),
            { data => $self->cbqz->json->encode($meet_status_quizzes) },
        );
    }
};

sub quiz_event ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');
    my $event      = $self->req_body_json;

    if ( $event->{event_data}{form} and $event->{event_data}{form} eq 'question' ) {
        try {
            my $question = CBQZ::Model::Question->new->load( $event->{question}{question_id} );
            $question->obj->update({ used => \'used + 1' })
                if ( $question and $question->is_usable_by( $self->stash('user') ) );
        }
        catch {
            $self->warn($_);
        };
    }

    try {
        my $program = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );
        E->throw('User does not have access to the quiz referenced') unless (
            grep { $_->{quiz_id} == $event->{metadata}{quiz_id} } @{
                CBQZ::Model::Quiz->new->quizzes_for_user( $self->stash('user'), $program )
            }
        );

        my $quiz = CBQZ::Model::Quiz->new->load( $event->{metadata}{quiz_id} );
        $quiz->obj->update({ metadata => $self->cbqz->json->encode( $event->{metadata} ) });
        $quiz->obj->update({ quizmaster => $self->stash('user')->obj->realname })
            if ( $quiz->obj->quizmaster ne $self->stash('user')->obj->realname );

        my $quiz_question_data = {
            quiz_id         => $event->{metadata}{quiz_id},
            question_number => $event->{event_data}{number},
            team            => $event->{event_data}{team}{name},
            form            => $event->{event_data}{form},
        };

        if ( $event->{event_data}{form} and $event->{event_data}{form} eq 'question' ) {
            $quiz_question_data->{question_as} = $event->{question}{as};
            $quiz_question_data->{$_}          = $event->{question}{$_}
                for ( qw( question_id book chapter verse question answer type score ) );
        }

        $quiz_question_data->{quizzer} = $event->{event_data}{quizzer}{name}
            if ( defined $event->{event_data}{quizzer}{name} );
        $quiz_question_data->{result} = $event->{event_data}{result}
            if ( defined $event->{event_data}{result} );

        $quiz_question_data = CBQZ::Model::QuizQuestion->new->create($quiz_question_data)->data;
        delete $quiz_question_data->{question};

        $quiz_data_ws->( $self, $quiz, $cbqz_prefs );

        $self->render( json => {
            success       => 1,
            quiz_question => $quiz_question_data,
        } );
    }
    catch {
        $self->warn($_);
        $self->render( json => { error => $self->clean_error($_) } );
    };

    return;
}

sub delete_quiz_event ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');
    my $event      = $self->req_body_json;

    try {
        my $program = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );
        E->throw('User does not have access to the quiz referenced') unless (
            grep { $_->{quiz_id} == $event->{metadata}{quiz_id} } @{
                CBQZ::Model::Quiz->new->quizzes_for_user( $self->stash('user'), $program )
            }
        );

        my $quiz = CBQZ::Model::Quiz->new->load( $event->{metadata}{quiz_id} );
        $quiz->obj->update({ metadata => $self->cbqz->json->encode( $event->{metadata} ) });

        CBQZ::Model::QuizQuestion->new->load({
            quiz_id         => $event->{metadata}{quiz_id},
            question_number => $event->{question_number},
        })->obj->delete;

        $quiz_data_ws->( $self, $quiz, $cbqz_prefs );

        $self->render( json => { success => 1 } );
    }
    catch {
        $self->warn($_);
        $self->render( json => { error => $self->clean_error($_) } );
    };

    return;
}

sub mark ($self) {
    my $json = $self->req_body_json;
    my $return_json;

    try {
        my $question = CBQZ::Model::Question->new->load( $json->{question_id} );
        E->throw('Failed to load question') unless ($question);

        my ( $is_owned_by, $is_shared_to ) = (
            $question->is_owned_by( $self->stash('user') ),
            $question->is_shared_to( $self->stash('user') ),
        );
        E->throw('User does not have access to the question referenced')
            unless ( $is_owned_by or $is_shared_to );

        $json->{reason} .= ' [' . join( '',
            map { uc( substr( $_, 0, 1 ) ) }
                split( /\s+/, $self->stash('user')->obj->realname )
        ) . ']' if ( $question->is_shared_set );

        $json->{reason} = $question->obj->marked . '; ' . $json->{reason} if ( $question->obj->marked );
        $question->obj->update({ marked => $json->{reason} });
        $return_json = { success => 1 };
    }
    catch {
        $return_json = { error => $self->clean_error($_) };
    };

    return $self->render( json => $return_json );
}

sub replace ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');
    my $set        = CBQZ::Model::QuestionSet->new->load( $cbqz_prefs->{question_set_id} );
    my $request    = $self->req_body_json;

    try {
        my $program = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );
        E->throw('User does not have access to the quiz referenced by quiz ID') unless (
            grep { $_->{quiz_id} == $request->{quiz_id} } @{
                CBQZ::Model::Quiz->new->quizzes_for_user( $self->stash('user'), $program )
            }
        );

        if ( $set and $set->is_usable_by( $self->stash('user') ) ) {
            my $results = CBQZ::Model::Quiz->new->load( $request->{quiz_id} )->replace( $request, $cbqz_prefs );
            $self->render( json => {
                question => (@$results) ? $results->[0] : undef,
                error    => (@$results) ? undef : 'Failed to find question of that type',
            } );
        }
    }
    catch {
        $self->render( json => {
            error => $self->clean_error($_),
        } );
    };

    return;
}

sub close ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');

    try {
        my $program = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );
        E->throw('User does not have access to the quiz referenced by quiz ID') unless (
            grep { $_->{quiz_id} == $self->req->param('quiz_id') } @{
                CBQZ::Model::Quiz->new->quizzes_for_user( $self->stash('user'), $program )
            }
        );

        my $quiz = CBQZ::Model::Quiz->new->load( $self->req->param('quiz_id') );
        $quiz->obj->update({ state => 'closed' });

        $quiz_data_ws->( $self, $quiz, $cbqz_prefs );

        $self->stash('user')->event('close_quiz');
    }
    catch {
        $self->flash( message => $self->clean_error($_) );
    };

    return $self->redirect_to('/quizroom');
}

sub rearrange_quizzers ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');
    my $request    = $self->req_body_json;

    try {
        my $program = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );
        E->throw('User does not have access to the quiz referenced by quiz ID') unless (
            grep { $_->{quiz_id} == $request->{metadata}{quiz_id} } @{
                CBQZ::Model::Quiz->new->quizzes_for_user( $self->stash('user'), $program )
            }
        );

        my $quiz          = CBQZ::Model::Quiz->new->load( $request->{metadata}{quiz_id} );
        my $quizzers_data = $quiz->parse_quiz_teams_quizzers( $request->{quizzers_data} );

        E->throw('There appears to be a team missing in the submitted lineup') unless (
            join( '|', sort map { $_->{team}{name} } @$quizzers_data ) eq
            join( '|', sort map { $_->{team}{name} } @{ $request->{metadata}{quiz_teams_quizzers} } )
        );

        E->throw('There appears to be a quizzer missing in the submitted lineup') unless (
            join( '|', sort map { map { $_->{name} } @{ $_->{quizzers} } } @$quizzers_data ) eq
            join( '|', sort map { map { $_->{name} } @{ $_->{quizzers} } }
                @{ $request->{metadata}{quiz_teams_quizzers} } )
        );

        for my $team_set (@$quizzers_data) {
            for my $quizzer ( @{ $team_set->{quizzers} } ) {
                my ($matched_quizzer) = grep {
                    $_->{name} eq $quizzer->{name}
                } map { @{ $_->{quizzers} } } @{ $request->{metadata}{quiz_teams_quizzers} };

                if ($matched_quizzer) {
                    my $bib = $quizzer->{bib};
                    $quizzer = $matched_quizzer;
                    $quizzer->{bib} = $bib;
                }
            }

            my ($matched_team) = grep {
                $_->{team}{name} eq $team_set->{team}{name}
            } @{ $request->{metadata}{quiz_teams_quizzers} };

            if ($matched_team) {
                $matched_team->{quizzers} = $team_set->{quizzers};
                $team_set = $matched_team;
            }
        }

        $request->{metadata}{quiz_teams_quizzers} = $quizzers_data;
        $quiz->obj->update({ metadata => $self->cbqz->json->encode( $request->{metadata} ) });

        $quiz_data_ws->( $self, $quiz, $cbqz_prefs );

        $self->render( json => {
            success             => 1,
            quiz_teams_quizzers => $quizzers_data,
        } );
    }
    catch {
        $self->render( json => {
            error => $self->clean_error($_),
        } );
    };

    return;
}

sub status ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');
    my $status     = {};

    try {
        $status     = $self->req_body_json || {};
        my $quiz_id = delete $status->{quiz_id} || 0;

        my $program = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );
        E->throw('User does not have access to the quiz referenced by quiz ID') unless (
            grep { $_->{quiz_id} == $quiz_id } @{
                CBQZ::Model::Quiz->new->quizzes_for_user( $self->stash('user'), $program )
            }
        );

        my $quiz = CBQZ::Model::Quiz->new->load($quiz_id);

        if ( keys %$status ) {
            $quiz->obj->update({ status => $quiz->json->encode($status) });
            $quiz_data_ws->( $self, $quiz, $cbqz_prefs );
        }
        else {
            $status = $quiz->json->decode( $quiz->obj->status );
        }
    };

    return $self->render( json => { status => $status } );
}

1;
