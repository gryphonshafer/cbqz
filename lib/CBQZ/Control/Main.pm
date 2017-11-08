package CBQZ::Control::Main;

use Mojo::Base 'Mojolicious::Controller';
use exact;
use Try::Tiny;
use CBQZ::Model::User;
use CBQZ::Model::Program;
use CBQZ::Model::MaterialSet;
use CBQZ::Model::QuestionSet;

sub index ($self) {
    unless ( $self->stash('user') ) {
        $self->stash(
            programs  => [ CBQZ::Model::Program->new->every_data ],
            recaptcha => $self->config->get( 'recaptcha', 'public_key' ),
        );
    }
    else {
        $self->stash( material_sets_count => CBQZ::Model::MaterialSet->new->rs->count );
    }
}

sub login ($self) {
    my $user = CBQZ::Model::User->new;
    my $e;
    try {
        $user = $user->login( { map { $_ => $self->param($_) } qw( name passwd ) } );
    }
    catch {
        $e = $self->clean_error($_);
        $self->info( 'Login failure (in controller): ' . $e );
        $self->flash( message => "Login failed. ($e) Please try again." );
    };
    return $self->redirect_to('/') if ($e);

    $self->info( 'Login success for: ' . $user->obj->name );
    $self->session(
        'user_id' => $user->obj->id,
        'time'    => time,
    );

    return $self->redirect_to('/');
}

sub logout ($self) {
    $self->info(
        'Logout requested from: ' .
        ( ( $self->stash('user') ) ? $self->stash('user')->obj->name : '(Unlogged-in user)' )
    );
    $self->session(
        'user_id' => undef,
        'time'    => undef,
    );

    return $self->redirect_to('/');
}

sub create_user ($self) {
    my $user = CBQZ::Model::User->new;
    my $e;
    try {
        my $params = $self->params;
        delete $params->{'g-recaptcha-response'};

        $user = $user->create($params);
        $self->login;
    }
    catch {
        $e = $self->clean_error($_);
        $self->info( 'Create user failure (in controller): ' . $e );
        $self->flash( message => "Create user failed. ($e) Please try again." );
    };

    return $self->redirect_to('/');
}

sub path ($self) {
    return $self->render( text => 'var cntlr = "' . $self->url_for->path('/main') . '";' );
}

sub data ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');

    my @selected_chapters = map {
        $_->{book} . '|' . $_->{chapter}
    } @{ $cbqz_prefs->{selected_chapters} };

    return $self->render( json => {
        programs        => [ map { $_->data } $self->stash('user')->programs ],
        material_sets   => [ CBQZ::Model::MaterialSet->new->every_data ],
        weight_chapters => $cbqz_prefs->{weight_chapters} // 0,
        weight_percent  => $cbqz_prefs->{weight_percent}  // 50,
        program_id      => $cbqz_prefs->{program_id}      || undef,
        question_set_id => $cbqz_prefs->{question_set_id} || undef,
        material_set_id => $cbqz_prefs->{material_set_id} || undef,
        question_set    => undef,
        question_sets   => [ map {
            my $set = $_->data;
            for ( @{ $set->{statistics} } ) {
                unless (
                    $cbqz_prefs->{question_set_id} and
                    $cbqz_prefs->{question_set_id} == $set->{question_set_id}
                ) {
                    $_->{selected} = 0;
                }
                else {
                    my $id = $_->{book} . '|' . $_->{chapter};
                    $_->{selected} = ( grep { $id eq $_ } @selected_chapters ) ? 1 : 0;
                }
            }
            $set;
        } $self->stash('user')->question_sets ],
    } );
}

sub question_set_create ($self) {
    return $self->render( json => {
        question_set => CBQZ::Model::QuestionSet->new->create(
            $self->stash('user'),
            $self->req_body_json->{name},
        )->data
    } );
}

sub question_set_delete ($self) {
    # TODO: prevent delete if user doesn't own the set
    CBQZ::Model::QuestionSet->new->load( $self->req_body_json->{question_set_id} )->obj->delete;
    return $self->render( json => { success => 1 } );
}

sub question_set_rename ($self) {
    my $data = $self->req_body_json;

    # TODO: prevent rename if user doesn't own the set
    my $set = CBQZ::Model::QuestionSet->new->load( $data->{question_set_id} )->obj;
    $set->name( $data->{name} );
    $set->update;

    return $self->render( json => { success => 1 } );
}

1;
