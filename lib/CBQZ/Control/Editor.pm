package CBQZ::Control::Editor;

use Mojo::Base 'Mojolicious::Controller';
use exact;
use MIME::Base64 'decode_base64';
use Try::Tiny;
use CBQZ::Model::MaterialSet;
use CBQZ::Model::QuestionSet;
use CBQZ::Model::Question;
use CBQZ::Model::Program;

sub path ($self) {
    return $self->render( text => 'var cntlr = "' . $self->url_for('/editor') . '";' );
}

sub data ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');

    my $data = {
        metadata  => {},
        questions => { data => {} },
        material  => { Error => { 1 => { 1 => {
            book    => 'Error',
            chapter => 1,
            verse   => 1,
            text    =>
                'An error occurred while trying to load data. ' .
                'This is likely due to invalid settings on the main page. ' .
                'Visit the main page and verify your settings.',
        } } } },
    };

    try {
        $data->{material} = CBQZ::Model::MaterialSet->new->load(
            $cbqz_prefs->{material_set_id},
        )->get_material;

        $data->{metadata} = {
            types => CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} )->types_list,
            books => [ sort { $a cmp $b } keys %{ $data->{material} } ],
        };

        my $set = CBQZ::Model::QuestionSet->new->load( $cbqz_prefs->{question_set_id} );
        $data->{questions} = { data => (
            ( $set and $set->is_owned_by( $self->stash('user') ) ) ? $set->get_questions : {},
        ) };
    }
    catch {
        $self->warn($_);
        $data->{error} =
            "An error occurred while trying to load data.\n" .
            "This is likely due to invalid settings on the main page.\n" .
            "Visit the main page and verify your settings.";
    };

    return $self->render( json => $data );
}

sub save ($self) {
    my $question   = $self->req_body_json;
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');

    $question->{marked} = 'Incomplete question' unless (
        $question->{type} and
        length( $question->{question} ) > 0 and
        length( $question->{answer} ) > 0
    );

    my $success = 0;
    unless ( $question->{question_id} ) {
        if (
            CBQZ::Model::QuestionSet->new->load(
                $cbqz_prefs->{question_set_id}
            )->is_owned_by( $self->stash('user') )
        ) {
            $question->{used}            = 0;
            $question->{question_set_id} = $cbqz_prefs->{question_set_id};

            $question = CBQZ::Model::Question->new->create($question)->data;
            $success  = 1;
        }
    }
    else {
        my $question_model = CBQZ::Model::Question->new->load( $question->{question_id} );
        if ( $question_model and $question_model->is_owned_by( $self->stash('user') ) ) {
            $question_model->obj->update($question);
            $success = 1;
        }
    }

    return $self->render( json => { question => $question } ) if ($success);
}

sub delete ($self) {
    my $question = CBQZ::Model::Question->new->load( $self->req_body_json->{question_id} );
    if ( $question and $question->is_owned_by( $self->stash('user') ) ) {
        $question->obj->delete;
        return $self->render( json => { success => 1 } );
    }
}

sub questions ($self) {
    try {
        if ( $self->param('quiz') ) {
            $self->stash( questions => [
                map { $_->data }
                grep { $_->is_owned_by( $self->stash('user') ) }
                map { CBQZ::Model::Question->new->load($_) }
                @{ $self->cbqz->json->decode( decode_base64( $self->param('quiz') ) ) }
            ] );
        }
        else {
            my $set = CBQZ::Model::QuestionSet->new->load(
                $self->decode_cookie('cbqz_prefs')->{question_set_id}
            );
            $self->stash(
                questions => [
                    sort {
                        $a->{book} cmp $b->{book} or
                        $a->{chapter} <=> $b->{chapter} or
                        $a->{verse} <=> $b->{verse} or
                        $a->{type} cmp $b->{type}
                    } @{ $set->get_questions([]) }
                ],
            ) if ( $set and $set->is_owned_by( $self->stash('user') ) );
        }
    }
    catch {
        $self->warn($_);
    };
}

sub auto_text ($self) {
    return $self->render( json => {
        question => CBQZ::Model::Question->new->auto_text(
            CBQZ::Model::MaterialSet->new->load(
                $self->decode_cookie('cbqz_prefs')->{material_set_id}
            ),
            $self->req_body_json,
        ),
    } );
}

1;
