package CBQZ::Control::Main;

use exact;
use Mojo::Base 'Mojolicious::Controller';
use Try::Tiny;
use CBQZ::Model::User;
use CBQZ::Model::Program;

sub index {
    my ($self) = @_;
    $self->stash( programs => CBQZ::Model::Program->new->list );
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
        $self->flash( message => "Login failed. $e. Please try again." );
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
        $user = $user->create( $self->params );
        $self->login;
    }
    catch {
        $e = $self->clean_error($_);
        $self->info( 'Create user failure (in controller): ' . $e );
        $self->flash( message => "Create user failed. $e. Please try again." );
    };

    return $self->redirect_to('/');
}

1;
