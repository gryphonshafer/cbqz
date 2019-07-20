package CBQZ::Control::Editor;

use Mojo::Base 'Mojolicious::Controller';
use exact;
use MIME::Base64 'decode_base64';
use Text::Unidecode 'unidecode';
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
        my $q_set = CBQZ::Model::QuestionSet->new->load( $cbqz_prefs->{question_set_id} );
        $data->{questions} = { data => (
            ( $q_set and $q_set->is_usable_by( $self->stash('user') ) ) ? $q_set->get_questions : {},
        ) };

        my $material_set    = CBQZ::Model::MaterialSet->new->load( $cbqz_prefs->{material_set_id} );
        $data->{material}   = $material_set->get_material;
        $data->{book_order} = $material_set->get_books;

        my %books = map { $_ => 1 } keys %{ $data->{material} }, keys %{ $data->{questions}{data} };

        $data->{metadata} = {
            types => CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} )->types_list,
            books => ( $data->{book_order} || [ sort { $a cmp $b } keys %books ] ),
        };
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

    ( $question->{$_} = unidecode( $question->{$_} || '' ) ) =~ s/&nbsp;/ /g
        for ( qw( question answer marked ) );

    $question->{marked} = 'Incomplete question' unless (
        $question->{type} and
        length( $question->{question} ) > 0 and
        length( $question->{answer} ) > 0
    );
    $question->{marked} = undef unless ( $question->{marked} );

    my $success = 0;
    unless ( $question->{question_id} ) {
        if (
            CBQZ::Model::QuestionSet->new->load(
                $cbqz_prefs->{question_set_id}
            )->is_usable_by( $self->stash('user') )
        ) {
            $question->{used}            = 0;
            $question->{question_set_id} = $cbqz_prefs->{question_set_id};

            my $question_model = CBQZ::Model::Question->new->create($question);
            $question_model->calculate_score(
                CBQZ::Model::MaterialSet->new->load(
                    $self->decode_cookie('cbqz_prefs')->{material_set_id}
                )
            );

            $question = $question_model->data;
            $success  = 1;
        }
    }
    else {
        my $question_model = CBQZ::Model::Question->new->load( $question->{question_id} );
        if ( $question_model and $question_model->is_usable_by( $self->stash('user') ) ) {
            $question_model->obj->update($question);
            $question->{score} = $question_model->calculate_score(
                CBQZ::Model::MaterialSet->new->load(
                    $self->decode_cookie('cbqz_prefs')->{material_set_id}
                )
            );
            $success = 1;
        }
    }

    return $self->render( json => { question => $question } ) if ($success);
}

sub delete ($self) {
    my $question = CBQZ::Model::Question->new->load( $self->req_body_json->{question_id} );
    if ( $question and $question->is_usable_by( $self->stash('user') ) ) {
        $question->obj->delete;
        return $self->render( json => { success => 1 } );
    }
}

sub questions ($self) {
    try {
        if ( $self->param('quiz') ) {
            $self->stash( questions => [
                map { $_->data }
                grep { $_->is_usable_by( $self->stash('user') ) }
                map { CBQZ::Model::Question->new->load($_) }
                @{ $self->cbqz->json->decode( decode_base64( $self->param('quiz') ) ) }
            ] );
        }
        else {
            my $q_set = CBQZ::Model::QuestionSet->new->load(
                $self->decode_cookie('cbqz_prefs')->{question_set_id}
            );

            my $m_set = CBQZ::Model::MaterialSet->new->load(
                $self->decode_cookie('cbqz_prefs')->{material_set_id}
            );
            my $i = 1;
            my $book_order_map = { map { $_ => $i++ } @{ ($m_set) ? $m_set->get_books : [] } };

            $self->stash(
                questions => [
                    sort {
                        $book_order_map->{ $a->{book} } and $book_order_map->{ $b->{book} } and
                        $book_order_map->{ $a->{book} } <=> $book_order_map->{ $b->{book} } or

                        $a->{book} cmp $b->{book} or
                        $a->{chapter} <=> $b->{chapter} or
                        $a->{verse} <=> $b->{verse} or
                        $a->{type} cmp $b->{type}
                    } @{ $q_set->get_questions([]) }
                ],
            ) if ( $q_set and $q_set->is_usable_by( $self->stash('user') ) );
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
