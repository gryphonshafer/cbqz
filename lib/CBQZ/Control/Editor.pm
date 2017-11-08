package CBQZ::Control::Editor;

use Mojo::Base 'Mojolicious::Controller';
use exact;
use CBQZ::Model::MaterialSet;
use CBQZ::Model::QuestionSet;
use CBQZ::Model::Question;
use CBQZ::Model::Program;

sub path ($self) {
    return $self->render( text => 'var cntlr = "' . $self->url_for->path('/editor') . '";' );
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
        question => {
            ( map { $_ => undef } qw( question_id book chapter verse question answer type used marked ) ),
        },
        material => {
            data           => $material,
            search         => undef,
            matched_verses => undef,
            ( map { $_ => undef } map { $_, $_ . 's' } qw( book chapter verse ) ),
        },
        questions => {
            data               => $questions,
            question_id        => undef,
            marked_question_id => undef,
            marked_questions   => [],
            questions          => undef,
            sort_by            => 'desc_ref',
            ( map { $_ => undef } map { $_, $_ . 's' } qw( book chapter ) ),
        },
    } );
}

sub save ($self) {
    my $question   = $self->req_body_json;
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');

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

1;
