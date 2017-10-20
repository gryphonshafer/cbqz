package CBQZ::Control::Main;

use exact;
use Mojo::Base 'Mojolicious::Controller';
use Try::Tiny;
use CBQZ::Model::User;
use CBQZ::Model::Program;
use CBQZ::Model::MaterialSet;

sub index {
    my ($self) = @_;

    unless ( $self->session('user_id') ) {
        $self->stash(
            programs  => [ CBQZ::Model::Program->new->every_data ],
            recaptcha => $self->config->get( 'recaptcha', 'public_key' ),
        );
    }
    else {
        $self->stash( material_sets_count => CBQZ::Model::MaterialSet->new->rs->count );
    }
}

sub login {
    my ($self) = @_;

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

sub logout {
    my ($self) = @_;

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

sub create_user {
    my ($self) = @_;

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

sub path {
    my ($self) = @_;
    return $self->render( text => 'var cntlr = "' . $self->url_for->path('/main') . '";' );
}

sub data {
    my ($self) = @_;
    return $self->render( json => {
        programs        => [ map { $_->data } $self->stash('user')->programs ],
        material_sets   => [ CBQZ::Model::MaterialSet->new->every_data ],
        weight_chapters => 0,
        weight_percent  => 50,
        question_sets   => [ map {
            my $set = $_->data;
            $_->{selected} = undef for ( @{ $set->{statistics} } );
            $set;
        } $self->stash('user')->question_sets ],
        ( map { $_ => undef } qw( question_set program_id question_set_id material_set_id ) ),
    } );
}

1;
