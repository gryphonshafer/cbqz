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
        $user = $user->login( { map { $_ => $self->param($_) } qw( username passwd ) } );
    }
    catch {
        $e = $self->clean_error($_);
        $self->info( 'Login failure (in controller): ' . $e );
        $self->flash( message => "Login failed. ($e) Please try again." );
    };
    return $self->redirect_to('/') if ($e);

    $self->info( 'Login success for: ' . $user->obj->username );
    $self->session(
        'user_id' => $user->obj->id,
        'time'    => time,
    );

    return $self->redirect_to('/');
}

sub logout ($self) {
    $self->info(
        'Logout requested from: ' .
        ( ( $self->stash('user') ) ? $self->stash('user')->obj->username : '(Unlogged-in user)' )
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
    return $self->render( text => 'var cntlr = "' . $self->url_for('/main') . '";' );
}

sub data ($self) {
    my $cbqz_prefs = $self->decode_cookie('cbqz_prefs');

    return $self->render( json => {
        program_id      => $cbqz_prefs->{program_id}      || undef,
        question_set_id => $cbqz_prefs->{question_set_id} || undef,
        material_set_id => $cbqz_prefs->{material_set_id} || undef,
        material_sets   => [
            sort { $b->{name} cmp $a->{name} }
            CBQZ::Model::MaterialSet->new->every_data
        ],
        programs => [
            sort { $a->{name} cmp $b->{name} }
            map { $_->data }
            $self->stash('user')->programs
        ],
        question_sets => [
            sort {
                $b->{share} cmp $a->{share} ||
                $b->{name} cmp $a->{name}
            }
            ( map { +{ %{ $_->data }, share => 0 } } $self->stash('user')->question_sets ),
            ( map { +{ %{ $_->data }, share => 1 } } $self->stash('user')->shared_question_sets ),
        ],
    } );
}

sub question_set_create ($self) {
    CBQZ::Model::QuestionSet->new->create(
        $self->stash('user'),
        $self->req->param('name'),
    );

    $self->flash( message => {
        type => 'success',
        text => 'Question set created.',
    } );

    return $self->redirect_to('/main/question_sets');
}

sub question_set_rename ($self) {
    my $set = CBQZ::Model::QuestionSet->new->load( $self->req->param('question_set_id') );

    if ( $set and $set->is_owned_by( $self->stash('user') ) ) {
        $set->obj->update({ name => $self->req->param('name') });

        $self->flash( message => {
            type => 'success',
            text => 'Question set renamed.',
        } );
    }
    else {
        $self->flash( message => 'Failed to rename question set.' );
    }

    return $self->redirect_to('/main/question_sets');
}

sub question_set_delete ($self) {
    my $set = CBQZ::Model::QuestionSet->new->load( $self->req->param('question_set_id') );

    if ( $set and $set->is_owned_by( $self->stash('user') ) ) {
        $set->obj->delete;

        $self->flash( message => {
            type => 'success',
            text => 'Question set deleted.',
        } );
    }
    else {
        $self->flash( message => 'Failed to delete question set.' );
    }

    return $self->redirect_to('/main/question_sets');
}

sub question_set_reset ($self) {
    my $set = CBQZ::Model::QuestionSet->new->load( $self->req->param('question_set_id') );
    if ( $set and $set->is_owned_by( $self->stash('user') ) ) {
        $set->obj->questions->update({ used => 0 });

        $self->flash( message => {
            type => 'success',
            text => 'Question set use counters reset.',
        } );
    }
    else {
        $self->flash( message => 'An error occurred; unable to reset set.' );
    };

    return $self->redirect_to('/main/question_sets');
}

sub clone_question_set ($self) {
    my $set = CBQZ::Model::QuestionSet->new->load( $self->req->param('question_set_id') );
    try {
        $set->clone(
            $self->stash('user'),
            $self->req->param('new_set_name'),
            'fork',
        );

        $self->flash( message => {
            type => 'success',
            text => join( ' ',
                'Question set clone process started successfully.',
                'It cant take potentially up to 60 seconds to complete.',
                'You can refresh this page to view the progress.',
            ),
        } );
    }
    catch {
        $self->error($_);
        $self->flash( message => 'An error occurred; unable to clone set.' );
    };

    return $self->redirect_to('/main/question_sets');
}

sub material_data ($self) {
    my $material = { Error => { 1 => { 1 => {
        book    => 'Error',
        chapter => 1,
        verse   => 1,
        text    =>
            'An error occurred while trying to load data. ' .
            'This is likely due to invalid settings on the main page. ' .
            'Visit the main page and verify your settings.',
    } } } };

    try {
        $material = CBQZ::Model::MaterialSet->new->load(
            $self->decode_cookie('cbqz_prefs')->{material_set_id}
        )->get_material;
    }
    catch {
        $self->warn($_);
    };

    return $self->render( json => { material => $material } );
}

sub edit_user ($self) {
    if ( $self->req->param('type') eq 'password' ) {
        unless (
            $self->req->param('old') and
            $self->req->param('new1') and
            $self->req->param('new2')
        ) {
            $self->flash( message => 'Not all 3 form fields were filled out.' );
        }
        elsif ( $self->req->param('new1') ne $self->req->param('new2') ) {
            $self->flash( message => 'The 2 new password fields did not match.' );
        }
        else {
            try {
                $self->stash('user')->change_passwd( $self->req->param('new1'), $self->req->param('old') );
            }
            catch {
                $self->flash( message => $self->clean_error($_) );
            }
            finally {
                unless (@_) {
                    $self->flash( message => {
                        type => 'success',
                        text => 'Password change successful.',
                    } );
                }
            };
        }
    }
    elsif ( $self->req->param('type') eq 'username' ) {
        try {
            $self->stash('user')->change_name( $self->req->param('value') );
        }
        catch {
            $self->flash( message => $self->clean_error($_) );
        }
        finally {
            unless (@_) {
                $self->flash( message => {
                    type => 'success',
                    text => 'Username change successful.',
                } );
            }
        };
    }
    else {
        try {
            $self->stash('user')->obj->update({ $self->req->param('type') => $self->req->param('value') });
        }
        catch {
            $self->flash( message => 'Something went wrong when changing ' . $self->req->param('type') );
        }
        finally {
            unless (@_) {
                $self->flash( message => {
                    type => 'success',
                    text => 'User account edit successful.',
                } );
            }
        };
    }

    return $self->redirect_to('/');
}

sub question_sets ($self) {
    $self->stash(
        user_question_sets => [
            map {
                +{
                    %{ $_->data },
                    count => $_->obj->questions->count,
                    used  => $_->obj->questions->search( { used => { '>', 0 } } )->count,
                    users => [
                        sort { $a->{username} cmp $b->{username} }
                        map {
                            +{
                                username => $_->user->username,
                                realname => $_->user->realname,
                                type     => $_->type,
                            }
                        }
                        $_->obj->user_question_sets
                    ],
                };
            } $self->stash('user')->question_sets
        ],
        published_sets => [ map { +{
            $_->question_set->get_inflated_columns,
            count => $_->question_set->questions->count,
            used  => $_->question_set->questions->search( { used => { '>', 0 } } )->count,
        } } $self->stash('user')->obj->user_question_sets->search({ type => 'Publish' })->all ],
    );
}

sub set_select_users ($self) {
    my $set = CBQZ::Model::QuestionSet->new->load( $self->req->param('question_set_id') );

    $self->stash(
        set   => $set,
        users => $set->users_to_select( $self->stash('user'), $self->req->param('type') ),
    );
}

sub save_set_select_users ($self) {
    my $set = CBQZ::Model::QuestionSet->new->load( $self->req->param('question_set_id') );

    try {
        $set->save_set_select_users(
            $self->stash('user'),
            $self->req->param('type'),
            $self->req->every_param('selected_users'),
        );

        $self->flash( message => {
            type => 'success',
            text => 'User selection saved.',
        } );
    }
    catch {
        $self->flash( message => 'An error occurred; failed to save user selection.' );
    };

    return $self->redirect_to('/main/question_sets');
}

1;
