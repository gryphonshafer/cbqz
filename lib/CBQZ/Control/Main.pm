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
    my $set = CBQZ::Model::QuestionSet->new->load( $self->req_body_json->{question_set_id} );
    if ( $set and $set->is_owned_by( $self->stash('user') ) ) {
        $set->obj->delete;
        return $self->render( json => { success => 1 } );
    }
}

sub question_set_rename ($self) {
    my $data = $self->req_body_json;
    my $set  = CBQZ::Model::QuestionSet->new->load( $data->{question_set_id} );
    if ( $set and $set->is_owned_by( $self->stash('user') ) ) {
        $set->obj->update({ name => $data->{name} });
        return $self->render( json => { success => 1 } );
    }
}

sub question_set_reset ($self) {
    try {
        my $set = CBQZ::Model::QuestionSet->new->load( $self->req->param('question_set_id') );
        if ( $set and $set->is_owned_by( $self->stash('user') ) ) {
            $set->obj->questions->update({ used => 0 });

            $self->flash( message => {
                type => 'success',
                text => 'Question set use counters reset.',
            } );
        }
    }
    catch {
        $self->flash( message => 'An error occurred; unable to reset set.' );
    };

    return $self->redirect_to('/main/question_sets');
}

sub clone_question_set ($self) {
    try {
        my $set = CBQZ::Model::QuestionSet->new->load( $self->req->param('question_set_id') );
        if ( $set and $set->is_owned_by( $self->stash('user') ) ) {
            my $pid = fork();
            if ( defined($pid) and $pid == 0 ) {
                $set->clone(
                    $self->stash('user'),
                    $self->req->param('new_set_name'),
                );
                exit;
            }

            $self->flash( message => {
                type => 'success',
                text => join( ' ',
                    'Question set clone process started successfully.',
                    'It cant take potentially up to 60 seconds to complete.',
                    'You can refresh this page to view the progress.',
                ),
            } );
        }
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
        ]
    );
}

# TODO: move most of below to model layer

sub set_select_users ($self) {
    $self->stash(
        set   => CBQZ::Model::QuestionSet->new->load( $self->req->param('question_set_id') ),
        users => [
            sort { $a->{username} cmp $b->{username} }
            @{
                $self->dq->sql(q{
                    SELECT
                        u.user_id AS id, u.username, u.realname,
                        SUM( IF( uqs.question_set_id = ? AND uqs.type = ?, 1, 0 ) ) AS checked
                    FROM user_program AS up
                    JOIN user AS u USING (user_id)
                    LEFT OUTER JOIN user_question_set AS uqs USING (user_id)
                    WHERE
                        up.program_id IN (
                           SELECT program_id FROM user_program WHERE user_id = ?
                        )
                        AND u.user_id != ?
                    GROUP BY 1

                })->run(
                    $self->req->param('question_set_id'),
                    $self->req->param('type'),
                    ( $self->stash('user')->obj->id ) x 2,
                )->all({})
            }
        ],
    );
}

sub save_set_select_users ($self) {
    my $set = CBQZ::Model::QuestionSet->new->load( $self->req->param('question_set_id') );
    if ( $set and $set->is_owned_by( $self->stash('user') ) ) {
        $self->dq->sql('DELETE FROM user_question_set WHERE question_set_id = ? AND type = ?')->run(
            $set->obj->id,
            $self->req->param('type'),
        );

        my $insert = $self->dq->sql(q{
            INSERT INTO user_question_set ( question_set_id, user_id, type ) VALUES ( ?, ?, ? )
        });

        $insert->run(
            $set->obj->id,
            $_,
            $self->req->param('type'),
        ) for ( @{ $self->req->every_param('selected_users') } );

        $self->flash( message => {
            type => 'success',
            text => 'User selection saved.',
        } );
    }
    else {
        $self->flash( message => 'An error occurred; failed to save user selection.' );
    }

    return $self->redirect_to('/main/question_sets');
}

1;
