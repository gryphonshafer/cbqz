package CBQZ::Control::Quizroom;

use Mojo::Base 'Mojolicious::Controller';
use exact;
use Try::Tiny;
use CBQZ::Model::Quiz;
use CBQZ::Model::Program;
use CBQZ::Model::MaterialSet;
use CBQZ::Model::Question;

sub quiz ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');

    try {
        my $program = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );

        $self->stash(
            question_types => $program->types_list,
            timer_values   => $program->timer_values,
        );
    }
    catch {
        $self->warn($_);
        $self->stash( message =>
            "An error occurred while trying to load data.\n" .
            "This is likely due to invalid settings on the main page.\n" .
            "Visit the main page and verify your settings."
        );
    };

    return;
}

sub path ($self) {
    my $cbqz_prefs       = $self->decode_cookie('cbqz_prefs');
    my $path             = $self->url_for('/quizroom');
    my $result_operation = '';

    try {
        $result_operation = CBQZ::Model::Program->new->load(
            $cbqz_prefs->{program_id}
        )->obj->result_operation;
    }
    catch {
        $self->warn($_);
    };

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

    return $self->render( json => {
        weight_chapters => $cbqz_prefs->{weight_chapters} // 0,
        weight_percent  => $cbqz_prefs->{weight_percent}  // 50,
        program_id      => $cbqz_prefs->{program_id}      || undef,
        question_set_id => $cbqz_prefs->{question_set_id} || undef,
        material_set_id => $cbqz_prefs->{material_set_id} || undef,
        question_set    => $question_set,
        question_types  => join( "\n",
            map {
                $_->[2] . ': ' . $_->[1][0] . '-' . $_->[1][1] . ' (' . join( ' ', @{ $_->[0] } ) . ')'
            } @{ $self->cbqz->json->decode(
                CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} )->obj->question_types
            ) }
        ),
    } );
}

sub data ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');

    my $data = {
        metadata => {
            types         => [],
            timer_default => 0,
            as_default    => 'Error',
            type_ranges   => [],
        },
        material  => { Error => { 1 => { 1 => {
            book    => 'Error',
            chapter => 1,
            verse   => 1,
            text    =>
                'An error occurred while trying to load data. ' .
                'This is likely due to invalid settings on the main page. ' .
                'Visit the main page and verify your settings.',
        } } } },
        questions => [],
    };

    try {
        my $program = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );
        my $set     = CBQZ::Model::QuestionSet->new->load( $cbqz_prefs->{question_set_id} );
        my $quiz    = ( $set and $set->is_usable_by( $self->stash('user') ) )
            ? CBQZ::Model::Quiz->new->generate($cbqz_prefs)
            : { error => 'User does not own requested question set' };

        $self->notice( $quiz->{error} ) if ( $quiz->{error} );

        $data->{metadata} = {
            types         => $program->types_list,
            timer_default => $program->obj->timer_default,
            as_default    => $program->obj->as_default,
            type_ranges   => [
                map {
                    my ( $label, $min, $max, @types ) = split(/\W+/);
                    [ \@types, [ $min, $max ], $label ];
                } split( /\r?\n/, $cbqz_prefs->{question_types} )
            ],
        };

        $data->{material} = CBQZ::Model::MaterialSet->new->load(
            $cbqz_prefs->{material_set_id}
        )->get_material;

        $data->{questions} = [
            map {
                $_->{number} = undef;
                $_->{as}     = undef;
                $_->{marked} = undef;
                $_;
            } @{ $quiz->{questions} }
        ];

        $data->{error} = ( $quiz->{error} ) ? $quiz->{error} : undef;
    }
    catch {
        $self->warn($_);
        $data->{error} =
            'An error occurred while trying to load data. ' .
            'This is likely due to invalid settings on the quiz configuration settings page. ' .
            'Visit the quiz configuration settings page and verify your settings';
    };

    return $self->render( json => $data );
}

sub used ($self) {
    my $question = CBQZ::Model::Question->new->load( $self->req_body_json->{question_id} );
    if ( $question and $question->is_usable_by( $self->stash('user') ) ) {
        $question->obj->update({ used => \'used + 1' });
        return $self->render( json => { success => 1 } );
    }
}

sub mark ($self) {
    my $json     = $self->req_body_json;
    my $question = CBQZ::Model::Question->new->load( $self->req_body_json->{question_id} );
    if ( $question and $question->is_usable_by( $self->stash('user') ) ) {
        $question->obj->update({ marked => $json->{reason} });
        return $self->render( json => { success => 1 } );
    }
}

sub replace ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');
    my $set = CBQZ::Model::QuestionSet->new->load( $cbqz_prefs->{question_set_id} );
    if ( $set and $set->is_usable_by( $self->stash('user') ) ) {
        my $results = CBQZ::Model::Quiz->new->replace( $self->req_body_json, $cbqz_prefs );
        return $self->render( json => {
            question => (@$results) ? $results->[0] : undef,
            error    => (@$results) ? undef : 'Failed to find question of that type.',
        } );
    }
}

1;
