package CBQZ::Control::Main;

use Mojo::Base 'Mojolicious::Controller';
use exact;
use Mojo::IOLoop;
use Try::Tiny;
use Text::Unidecode 'unidecode';
use Text::CSV_XS 'csv';
use CBQZ::Model::User;
use CBQZ::Model::Program;
use CBQZ::Model::MaterialSet;
use CBQZ::Model::QuestionSet;
use CBQZ::Model::Email;

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
        'user_id'           => $user->obj->id,
        'last_request_time' => time,
    );

    return $self->redirect_to('/');
}

sub logout ($self) {
    $self->info(
        'Logout requested from: ' .
        ( ( $self->stash('user') ) ? $self->stash('user')->obj->username : '(Unlogged-in user)' )
    );
    $self->session(
        'user_id'           => undef,
        'last_request_time' => undef,
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
    try {
        for my $set_id ( map { $_->{id} } @{
            $self->cbqz->json->decode(
                $self->req->param('set_data')
            )
        } ) {
            my $set = CBQZ::Model::QuestionSet->new->load($set_id);
            $set->obj->delete if ( $set and $set->is_owned_by( $self->stash('user') ) );
        }

        $self->stash('user')->event('question_sets_delete');

        $self->flash( message => {
            type => 'success',
            text => 'Question set(s) deleted.',
        } );
    }
    catch {
        $self->flash( message => 'Failed to delete question set(s).' );
    };

    return $self->redirect_to('/main/question_sets');
}

sub question_sets_reset ($self) {
    try {
        for my $set_id ( map { $_->{id} } @{
            $self->cbqz->json->decode(
                $self->req->param('set_data')
            )
        } ) {
            my $set = CBQZ::Model::QuestionSet->new->load($set_id);
            $set->obj->questions->update({ used => 0 })
                if ( $set and $set->is_owned_by( $self->stash('user') ) );
        }

        $self->stash('user')->event('question_sets_reset');

        $self->flash( message => {
            type => 'success',
            text => 'Question set use counters reset.',
        } );
    }
    catch {
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
        );
        $self->stash('user')->event('clone_question_set');

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
            $self->flash( message =>
                'Something went wrong' . (
                    ( $self->req->param('type') ) ? ' when changing ' . $self->req->param('type') : ''
                ) . '.'
            );
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

    $self->stash('user')->event('edit_user');
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

                    publish_all   => $_->obj->user_question_sets
                        ->search({ type => 'publish', user_id => \q{ IS NULL }     })->count,
                    publish_users => $_->obj->user_question_sets
                        ->search({ type => 'publish', user_id => \q{ IS NOT NULL } })->count,
                    share_all     => $_->obj->user_question_sets
                        ->search({ type => 'share',   user_id => \q{ IS NULL }     })->count,
                    share_users   => $_->obj->user_question_sets
                        ->search({ type => 'share',   user_id => \q{ IS NOT NULL } })->count,
                };
            } $self->stash('user')->question_sets
        ],
        published_sets => [
            map { +{
                $_->question_set->get_inflated_columns,
                count => $_->question_set->questions->count,
                used  => $_->question_set->questions->search( { used => { '>', 0 } } )->count,
            } }
            $self->stash('user')->rs( 'UserQuestionSet', {
                type    => 'publish',
                user_id => [ $self->stash('user')->obj->id, undef ],
            })->all
        ],
    );
}

sub set_select_users ($self) {
    my $set = CBQZ::Model::QuestionSet->new->load( $self->req->param('question_set_id') );

    $self->stash(
        set       => $set,
        users     => $set->users_to_select( $self->stash('user'), $self->req->param('type') ),
        all_users => $set->obj->user_question_sets->search({
            type    => $self->req->param('type'),
            user_id => undef,
        })->count,
    );
}

sub save_set_select_users ($self) {
    my $set = CBQZ::Model::QuestionSet->new->load( $self->req->param('question_set_id') );

    try {
        my $email = CBQZ::Model::Email->new( type => 'new_shared_set' );
        $email->send({
            to   => $_->obj->email,
            data => {
                realname => $_->obj->realname,
                set_name => $set->obj->name,
                sharer   => $self->stash('user')->obj->realname,
            },
        }) for (
            map {
                CBQZ::Model::User->new->load($_)
            } @{
                $set->save_set_select_users(
                    $self->stash('user'),
                    $self->req->param('type'),
                    $self->req->every_param('selected_users'),
                )
            }
        );

        $self->cbqz->dq->sql(
            ( $self->req->param('all_users') )
                ? 'INSERT INTO user_question_set ( user_id, question_set_id, type ) VALUES ( NULL, ?, ? )'
                : 'DELETE FROM user_question_set WHERE user_id IS NULL AND question_set_id = ? AND type = ?'
        )->run( $set->obj->id, $self->req->param('type') );

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

sub export_question_set ($self) {
    my $set = CBQZ::Model::QuestionSet->new->load( $self->req->param('question_set_id') );

    if ( $set and $set->is_usable_by( $self->stash('user') ) ) {
        $self->stash('user')->event('export_question_set');

        my $questions = [
            sort {
                $a->{book} cmp $b->{book} or
                $a->{chapter} <=> $b->{chapter} or
                $a->{verse} <=> $b->{verse} or
                $a->{type} cmp $b->{type}
            } @{ $set->get_questions([]) }
        ];

        if ( $self->req->param('style') and $self->req->param('style') eq 'intl' ) {
            my $de_text = sub {
                my $text = lc( $_[0] );
                $text =~ s/<[^>]+?>//g;
                $text =~ s/\W+/ /g;
                $text =~ s/\s{2,}/ /g;
                return $text;
            };

            my $material = [];
            if ( my $material_set_id = $self->decode_cookie('cbqz_prefs')->{material_set_id} ) {
                try {
                    $material = [
                        map { $de_text->( $_->{text} ) } @{
                            CBQZ::Model::MaterialSet->new->load(
                                $self->decode_cookie('cbqz_prefs')->{material_set_id}
                            )->get_material([])
                        }
                    ];
                };
            }

            my $search = sub {
                my @text = split( /\s+/, $de_text->( $_[0] ) );

                for my $i ( 0 .. @text - 1 ) {
                    for my $j ( 0, 1 ) {
                        my $search_for = join( ' ', @text[ $j .. $i ] );
                        my @finds = grep { CORE::index( $_, $search_for ) > -1 } @$material;

                        return $i + 1 if ( @finds == 1 );
                    }
                }
                return 0;
            };

            for my $question ( grep { $_->{type} eq 'INT' or $_->{type} eq 'MA' } @$questions ) {
                if ( my $words = $search->( $question->{question} ) ) {
                    my $text = $question->{question};
                    $text =~ s|<span class="unique_word">|*|g;
                    $text =~ s|<span class="unique_chapter">|^|g;
                    $text =~ s|<span class="unique_phrase">|+|g;
                    $text =~ s|</span>|#|g;

                    my @text = split(/(?<=\s)|(?=\s)/, $text );

                    if ( $words * 2 > @text ) {
                        push( @text, ' ', '%' );
                    }
                    else {
                        splice( @text, $words * 2, 0, '%', ' ' );
                    }

                    $text = join( '', @text );
                    $text =~ s|\*|<span class="unique_word">|g;
                    $text =~ s|\^|<span class="unique_chapter">|g;
                    $text =~ s|\+|<span class="unique_phrase">|g;
                    $text =~ s|\#|</span>|g;

                    $text =~ s|\%|&#187;|g;
                    $question->{question} = $text;
                }
            }
        }

        $self->stash(
            style     => $self->req->param('style'),
            questions => $questions,
        );

        ( my $filename = $set->obj->name . '.xls' ) =~ s/[\\\/:?"<>|]+/_/g;
        $self->res->headers->content_type('application/vnd.ms-excel');
        $self->res->headers->content_disposition(qq{attachment; filename="$filename"});
    }
    else {
        $self->flash( message => 'Your user does not have rights to export the specified question set.' );
        return $self->redirect_to('/main/question_sets');
    }
}

sub import_question_set ($self) {
    my $types_list = CBQZ::Model::Program->new->load(
        $self->decode_cookie('cbqz_prefs')->{program_id}
    )->types_list;

    try {
        my $question_import = $self->req->upload('question_import');
        E->throw('Failed to retrieve import data')
            unless ( $question_import->filename and $question_import->size );

        my $csv_data = $question_import->slurp ||
            E->throw('Input unreadable; may be binary instead of CSV text');

        $csv_data //= '';
        $csv_data =~ s/\r//g;

        my $csv = csv( in => \$csv_data, headers => 'auto' ) ||
            E->throw('Input not a valid CSV file as defined by the instructions on the page');

        my $questions = [
            grep {
                my $type = $_->{type};

                $_->{book} and
                $_->{chapter} and
                $_->{verse} and
                $_->{type} and
                $_->{question} and
                $_->{answer} and
                scalar( grep { $type eq $_ } @$types_list );
            }
            map {
                my $question = $_;
                $question = { map { lc( unidecode($_) ) => unidecode( $question->{$_} ) } keys %$question };

                $question->{$_} =~ s/[<>]+//g for ( qw( question answer ) );
                $question->{$_} =~ s/\s{2,}/ /g for ( qw( book chapter verse type question answer ) );
                $question->{$_} =~ s/(^\s+|\s+$)//g for ( qw( book chapter verse type question answer ) );
                $question->{$_} =~ s/[^A-z]+//g for ( qw( book type ) );
                $question->{$_} =~ s/\D+//g for ( qw( chapter verse ) );

                +{ map { $_ => $question->{$_} } qw( book chapter verse type question answer ) };
            }
            @$csv
        ];

        E->throw(
            'Failed to parse uploaded data; Check that you have a CSV text file ' .
            'with properly named column headers as per the page instructions; ' .
            'Also check that your question types match the district program question types'
        ) unless (@$questions);

        my $question_set = CBQZ::Model::QuestionSet->new->create(
            $self->stash('user'),
            $self->req->param('question_set_name'),
        );
        my $material_set = CBQZ::Model::MaterialSet->new->load(
            $self->decode_cookie('cbqz_prefs')->{material_set_id},
        );

        Mojo::IOLoop->subprocess(
            sub {
                $question_set->import_questions(
                    $questions,
                    $material_set,
                );
            },
            sub {
                my ( $subprocess, $error, @results ) = @_;
                $self->error($error) if ($error);
            },
        );

        $self->stash('user')->event('import_question_set');

        $self->flash( message => {
            type => 'success',
            text =>
                'Import started successfully; Expecting to process ' . @$questions . ' records; ' .
                'Note that a fair amount of post-processing of the imported ' .
                'data will continue for a time after seeing this message; You can refresh this page and ' .
                'look at the Questions Count number to monitor progress.',
        } );
    }
    catch {
        $self->flash( message => 'Import failed; ' . $self->clean_error($_) );
    };

    return $self->redirect_to('/main/question_sets');
}

sub merge_question_sets ($self) {
    try {
        CBQZ::Model::QuestionSet->new->merge(
            [
                map { $_->{id} } @{
                    $self->cbqz->json->decode(
                        $self->req->param('set_data')
                    )
                }
            ],
            $self->stash('user'),
        );

        $self->flash( message => {
            type => 'success',
            text => 'Question sets merged successfully.',
        } );
    }
    catch {
        $self->flash( message => 'An error occurred when trying to merge question sets.' );
    };

    return $self->redirect_to('/main/question_sets');
}

sub auto_kvl ($self) {
    try {
        my $set_data     = $self->cbqz->json->decode( $self->req->param('set_data') );
        my $material_set = CBQZ::Model::MaterialSet->new->load(
            $self->decode_cookie('cbqz_prefs')->{material_set_id}
        );

        Mojo::IOLoop->subprocess(
            sub {
                CBQZ::Model::QuestionSet->new->load( $_->{id} )->auto_kvl(
                    $material_set,
                    $self->stash('user'),
                ) for (@$set_data);
            },
            sub {
                my ( $subprocess, $error, @results ) = @_;
                $self->error($error) if ($error);
            },
        );

        $self->flash( message => {
            type => 'success',
            text =>
                'Auto-KVL initiated successfully; The processing of data will continue for a time after ' .
                'seeing this message; You can refresh this page and look at the Questions Count number ' .
                'to monitor progress.',
        } );
    }
    catch {
        $self->flash( message => 'An error occurred when trying to auto-KVL.' );
    };

    return $self->redirect_to('/main/question_sets');
}

sub reset_password_start ($self) {
    my $user;

    try {
        $user = CBQZ::Model::User->new->load({ username => $self->param('username') })->obj;
    }
    catch {
        $self->flash( message => 'Unable to find that particular user in the system.' );
    };

    if ($user) {
        CBQZ::Model::Email->new( type => 'reset_password' )->send({
            to   => $user->email,
            data => {
                realname => $user->realname,
                username => $user->username,
                url      => $self->url_for('/reset_password')->query(
                    user => $user->username,
                    key => substr( $user->passwd, 0, 7 ),
                )->to_abs->to_string,
            },
        });

        $self->flash( message => {
            type => 'success',
            text =>
                'The password reset process has started. Look to your email for ' .
                'a message with instructions and the next step in the process.',
        } );
    }

    return $self->redirect_to('/');
}

sub reset_password_save ($self) {
    try {
        my $user = CBQZ::Model::User->new->load({ username => $self->param('user') });

        E->throw('Username/password incorrect in reset password save')
            unless ( substr( $user->obj->passwd, 0, 7 ) eq $self->param('key') );

        $user->change_passwd( $self->param('passwd') );

        $self->flash( message => {
            type => 'success',
            text => 'User account password changed.',
        } );
    }
    catch {
        $self->flash( message => 'Unable to change passsword for user.' );
    };

    return $self->redirect_to('/');
}

1;
