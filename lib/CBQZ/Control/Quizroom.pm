package CBQZ::Control::Quizroom;

use exact;
use Mojo::Base 'Mojolicious::Controller';
use CBQZ::Model::Quiz;
use CBQZ::Model::Program;
use CBQZ::Model::MaterialSet;

sub index {
    my ($self)     = @_;
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');
    my $program    = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );

    $self->stash(
        question_types => $program->types_list,
        timer_values   => $program->timer_values,
    );

    return;
}

sub path {
    my ($self)           = @_;
    my $cbqz_prefs       = $self->decode_cookie('cbqz_prefs');
    my $path             = $self->url_for->path('/quizroom');
    my $result_operation = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} )->obj->result_operation;

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

sub data {
    my ($self)     = @_;
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');
    my $quiz       = CBQZ::Model::Quiz->new->generate($cbqz_prefs);
    my $program    = CBQZ::Model::Program->new->load( $cbqz_prefs->{program_id} );

    $self->notice( $quiz->{error} ) if ( $quiz->{error} );

    return $self->render( json => {
        metadata => {
            types         => $program->types_list,
            timer_default => $program->obj->timer_default,
            as_default    => $program->obj->as_default,
            type_ranges   => $self->cbqz->json->decode( $program->obj->question_types ),
        },
        material => {
            data           => CBQZ::Model::MaterialSet->new->load( $cbqz_prefs->{material_set_id} )->get_material,
            search         => undef,
            matched_verses => undef,
            ( map { $_ => undef } map { $_, $_ . 's' } qw( book chapter verse ) ),
        },
        questions => [
            map {
                $_->{number} = undef;
                $_->{as}     = undef;
                $_->{marked} = undef;
                $_;
            } @{ $quiz->{questions} }
        ],
        question => {
            map { $_ => undef } qw( number type as used book chapter verse question answer marked )
        },
        quiz_view_hidden => 1,
        position         => 0,
        timer            => {
            value => 30,
            state => 'ready',
            label => 'Start Timer',
        },
        error => ( $quiz->{error} ) ? $quiz->{error} : undef,
    } );
}

sub used {
    my ($self) = @_;
    my $json   = $self->req_body_json;

    $self->dq->sql('UPDATE question SET used = used + 1 WHERE question_id = ?')->run( $json->{question_id} );
    return $self->render( json => {} );
}

sub mark {
    my ($self) = @_;
    my $json   = $self->req_body_json;

    $self->dq->sql('UPDATE question SET marked = ? WHERE question_id = ?')
        ->run( $json->{reason}, $json->{question_id} );

    # TODO: look for this return code in the JS
    return $self->render( json => { success => 1 } );
}

sub replace {
    my ($self) = @_;

    my $results = CBQZ::Model::Quiz->new->replace(
        $self->req_body_json,
        $self->decode_cookie('cbqz_prefs'),
    );

    return $self->render( json => {
        question => (@$results) ? $results->[0] : undef,
        error    => (@$results) ? undef : 'Failed to find question of that type.',
    } );
}

1;
