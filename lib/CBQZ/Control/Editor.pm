package CBQZ::Control::Editor;

use exact;
use Mojo::Base 'Mojolicious::Controller';
use CBQZ::Model::MaterialSet;
use CBQZ::Model::QuestionSet;
use CBQZ::Model::Program;

sub path {
    my ($self) = @_;
    return $self->render( text => 'var cntlr = "' . $self->url_for->path('/editor') . '";' );
}

sub data {
    my ($self) = @_;

    my $material  = CBQZ::Model::MaterialSet->new->load( $self->cookie('cbqz_sets_material') )->get_material;
    my $questions = CBQZ::Model::QuestionSet->new->load( $self->cookie('cbqz_sets_questions') )->get_questions;

    return $self->render( json => {
        metadata => {
            types => CBQZ::Model::Program->new->load( $self->cookie('cbqz_sets_program') )->types_list,
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

sub save {
    my ($self) = @_;
    my $question = $self->req_body_json;

    unless ( $question->{question_id} ) {
        $self->dq->sql(q{
            INSERT INTO question (
                question_set_id, book, chapter, verse, question, answer, type
            ) VALUES ( ?, ?, ?, ?, ?, ?, ? )
        })->run(
            $self->cookie('cbqz_sets_questions'),
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

sub delete {
    my ($self) = @_;
    my $json = $self->req_body_json;

    $self->dq->sql('DELETE FROM question WHERE question_id = ?')->run( $json->{question_id} );
    return $self->render( json => {} );
}

1;
