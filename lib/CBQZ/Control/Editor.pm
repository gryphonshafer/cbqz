package CBQZ::Control::Editor;

use Mojo::Base 'Mojolicious::Controller';
use exact;
use MIME::Base64 'decode_base64';
use CBQZ::Model::MaterialSet;
use CBQZ::Model::QuestionSet;
use CBQZ::Model::Question;
use CBQZ::Model::Program;

sub path ($self) {
    return $self->render( text => 'var cntlr = "' . $self->url_for('/editor') . '";' );
}

sub data ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');
    my $material   = CBQZ::Model::MaterialSet->new->load( $cbqz_prefs->{material_set_id} )->get_material;

    my $set = CBQZ::Model::QuestionSet->new->load( $cbqz_prefs->{question_set_id} );
    my $questions = ( $set and $set->is_owned_by( $self->stash('user') ) ) ? $set->get_questions : {};

    return $self->render( json => {
        metadata => {
            types => CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} )->types_list,
            books => [ sort { $a cmp $b } keys %$material ],
        },
        material  => $material,
        questions => { data => $questions },
    } );
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
    if ( $self->param('quiz') ) {
        $self->stash( questions => [
            map { $_->data }
            grep { $_->is_owned_by( $self->stash('user') ) }
            map { CBQZ::Model::Question->new->load($_) }
            @{ $self->cbqz->json->decode( decode_base64( $self->param('quiz') ) ) }
        ] );
    }
    else {
        my $set = CBQZ::Model::QuestionSet->new->load( $self->decode_cookie('cbqz_prefs')->{question_set_id} );
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
