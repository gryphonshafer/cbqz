package CBQZ::Control::Editor;

use exact;
use Mojo::Base 'Mojolicious::Controller';
use Try::Tiny;

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
    return $self->render( text => 'var cntlr = "' . $self->url_for->path('/editor') . '";' );
}

sub data {
    my ($self) = @_;

    my $material = {};
    $material->{ $_->{book} }{ $_->{chapter} }{ $_->{verse} } = $_ for (
        map {
            ( $_->{search} = lc( $_->{text} ) ) =~ s/<[^>]+>//g;
            $_->{search} =~ s/\W//g;
            $_;
        }
        @{
            $self->dq->sql(q{
                SELECT book, chapter, verse, text, key_class, key_type, is_new_para
                FROM material
                WHERE material_set_id = ?
            })->run(1)->all({})
        }
    );

    my $questions = {};
    $questions->{ $_->{book} }{ $_->{chapter} }{ $_->{question_id} } = $_ for (
        @{
            $self->dq->sql(q{
                SELECT question_id, book, chapter, verse, question, answer, type, used
                FROM question
                WHERE question_set_id = ?
            })->run( $self->session('question_set_id') )->all({})
        }
    );

    return $self->render( json => {
        metadata => {
            types => [ qw( INT MA CR CVR MACR MACVR QT QTN FTV FT2V FT FTN SIT ) ],
            books => [ sort { $a cmp $b } keys %$material ],
        },
        question => {
            ( map { $_ => undef } qw( question_id book chapter verse question answer type used ) ),
        },
        material => {
            data           => $material,
            search         => undef,
            matched_verses => undef,
            ( map { $_ => undef } map { $_, $_ . 's' } qw( book chapter verse ) ),
        },
        questions => {
            data        => $questions,
            question_id => undef,
            questions   => undef,
            ( map { $_ => undef } map { $_, $_ . 's' } qw( book chapter ) ),
        },
    } );
}

sub save {
    my ($self) = @_;
    my $question = $self->req_body_json;

    $self->dq->sql(q{
        INSERT INTO question (
            question_set_id, book, chapter, verse, question, answer, type
        ) VALUES ( ?, ?, ?, ?, ?, ?, ? )
    })->run(
        $self->session('question_set_id'),
        @$question{ qw( book chapter verse question answer type ) }
    );

    $question->{question_id} = $self->dq->sql('SELECT last_insert_id()')->run->value;
    $question->{used}        = 0;

    return $self->render( json => { question => $question } );
}

sub delete {
    my ($self) = @_;
    my $json = $self->req_body_json;

    $self->dq->sql('DELETE FROM question WHERE question_id = ?')->run( $json->{question_id} );
    return $self->render( json => {} );
}

1;
