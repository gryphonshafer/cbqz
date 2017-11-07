package CBQZ::Control::Editor;

use Mojo::Base 'Mojolicious::Controller';
use exact;
use CBQZ::Model::MaterialSet;
use CBQZ::Model::QuestionSet;
use CBQZ::Model::Program;

sub path ($self) {
    return $self->render( text => 'var cntlr = "' . $self->url_for->path('/editor') . '";' );
}

sub data ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');

    my $material  = CBQZ::Model::MaterialSet->new->load( $cbqz_prefs->{material_set_id} )->get_material;
    my $questions = CBQZ::Model::QuestionSet->new->load( $cbqz_prefs->{question_set_id} )->get_questions;

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

    unless ( $question->{question_id} ) {
        $self->dq->sql(q{
            INSERT INTO question (
                question_set_id, book, chapter, verse, question, answer, type
            ) VALUES ( ?, ?, ?, ?, ?, ?, ? )
        })->run(
            $cbqz_prefs->{question_set_id},
            @$question{ qw( book chapter verse question answer type ) },
        );

        $question->{question_id} = $self->dq->sql('SELECT last_insert_id()')->run->value;
        $question->{used}        = 0;
    }
    else {
        $self->dq->sql(q{
            UPDATE question
            SET book = ?, chapter = ?, verse = ?, question = ?, answer = ?, type = ?, marked = NULL
            WHERE question_id = ?
        })->run(
            @$question{ qw( book chapter verse question answer type ) },
            $question->{question_id},
        );
    }

    return $self->render( json => { question => $question } );
}

sub delete ($self) {
    $self->dq->sql('DELETE FROM question WHERE question_id = ?')->run( $self->req_body_json->{question_id} );
    return $self->render( json => { success => 1 } );
}

1;
