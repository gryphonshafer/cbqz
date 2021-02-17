package CBQZ::Control;

use Mojo::Base 'Mojolicious';
use exact -notry;
use Try::Tiny;
use Mojo::Loader 'load_class';
use Mojo::Util 'b64_decode';
use MojoX::Log::Dispatch::Simple;
use Text::CSV_XS 'csv';
use CBQZ;
use CBQZ::Model::User;
use CBQZ::Util::Format 'log_date';
use CBQZ::Util::Template 'tt_settings';
use CBQZ::Util::File 'most_recent_modified';

sub startup ($self) {
    my $cbqz   = CBQZ->new;
    my $config = $cbqz->config;

    $self->sub_version($config);

    # base URL handling
    $self->plugin('RequestBase');

    $self->static->paths->[0] =~ s|/public$|/static|;
    $self->sessions->cookie_name( $config->get( qw( mojolicious session cookie_name ) ) );
    $self->secrets( $config->get( 'mojolicious', 'secrets' ) );
    $self->config( $config->get( 'mojolicious', 'config' ) );
    $self->sessions->default_expiration( $config->get( qw( mojolicious session default_expiration ) ) );

    $self->setup_general_helpers($cbqz);
    $self->setup_logging($cbqz);
    $self->setup_templating($config);
    $self->setup_csv;
    $self->setup_socket($cbqz);

    # pre-load controllers
    if ( $self->mode eq 'production' ) {
        load_class( 'CBQZ::Control::' . $_ ) for qw( Main Editor Quizroom Admin Stats );
    }

    # before dispatch tasks
    $self->hook( 'before_dispatch' => sub ($self) {
        # expire the session if the last request time was over an hour ago
        my $last_request_time = $self->session('last_request_time');
        if (
            $last_request_time and
            $last_request_time < time - $config->get( qw( mojolicious session duration ) )
        ) {
            $self->session( expires => 1 );
            $self->redirect_to;
        }
        $self->session( 'last_request_time' => time );

        if ( my $user_id = $self->session('user_id') ) {
            my $user;
            try {
                $user = CBQZ::Model::User->new->load($user_id);
            }
            catch {
                $self->notice( 'Failed user load based on session "user_id" value: "' . $user_id . '"' );
            };

            if ($user) {
                $self->stash( 'user' => $user );
            }
            else {
                delete $self->session->{'user_id'};
            }
        }
    });

    # routes setup section
    my $anyone = $self->routes;

    $anyone->any('/')->to('main#index');
    $anyone->any( '/' . $_ )->to( controller => 'main', action => $_ ) for ( qw(
        index
        login
        logout
        create_user
        reset_password_start
        reset_password
        reset_password_save
    ) );

    my $authorized_user = $anyone->under( sub ($self) {
        return 1 if (
            $self->stash('user') and
            $self->stash('user')->has_any_role_in_program and
            $self->stash('user')->programs_count > 0
        );

        $self->info('Login required but not yet met');
        $self->redirect_to('/');
        return 0;
    } );

    my $admin_user = $authorized_user->under( sub ($self) {
        return 1 if (
            $self->stash('user') and (
                $self->stash('user')->has_role('administrator') or
                $self->stash('user')->has_role('director')
            )
        );

        $self->info('Unauthorized access attempt to /admin');
        $self->redirect_to('/');
        return 0;
    } );

    $admin_user->any('/admin')->to( controller => 'admin', action => 'index' );
    $admin_user->any( '/admin/' . $_ )->to( controller => 'admin', action => $_ ) for ( qw (
        index
        save_roles_changes
        config
        save_program_config
        build_draw
    ) );

    $authorized_user->any('/stats/room/:room')->to( controller => 'stats', action => 'room' );
    $authorized_user->any('/stats/room')->to( cb => sub ($self) { $self->redirect_to('/stats') } );

    $authorized_user->any( '/' . $_ )->to( controller => $_, action => 'index' ) for ( qw(
        editor
        quizroom
        stats
    ) );

    $authorized_user->any( '/main/' . $_ )->to( controller => 'main', action => $_ ) for ( qw(
        path
        data
        question_set_create
        question_set_rename
        question_set_delete
        question_sets_reset
        clone_question_set
        material
        material_data
        edit_user
        question_sets
        set_select_users
        save_set_select_users
        export_question_set
        import_question_set
        merge_question_sets
        auto_kvl
        reset_password_start
        reset_password_save
    ) );

    $authorized_user->any( '/editor/' . $_ )->to( controller => 'editor', action => $_ ) for ( qw(
        path
        data
        save
        delete
        questions
        auto_text
    ) );

    $authorized_user->any( '/quizroom/' . $_ )->to( controller => 'quizroom', action => $_ ) for ( qw(
        index
        path
        quiz_setup
        generate_quiz
        quiz
        data
        quiz_event
        delete_quiz_event
        mark
        replace
        close
        rearrange_quizzers
        status
    ) );

    $authorized_user->any( '/stats/' . $_ )->to( controller => 'stats', action => $_ ) for ( qw(
        index
        path
        quiz
        delete_practice_quiz
        delete_official_quiz
        live_scoresheet
        meet
        meet_status
        quiz_edit
    ) );

    return;
}

sub sub_version ( $self, $config ) {
    my @most_recent_modified = (
        localtime(
            most_recent_modified(
                map { $config->get( 'config_app', 'root_dir' ) . '/' . $_ }
                    qw( config db lib static templates )
            )
        )
    )[ 5, 4, 3, 2, 1 ];
    $most_recent_modified[0] += 1900;
    $most_recent_modified[1] += 1;
    $config->put( sub_version => sprintf( '%d.%02d.%02d.%02d.%02d', @most_recent_modified ) );
}

sub setup_general_helpers ( $self, $cbqz ) {
    # setup general helpers
    for my $command ( qw( clean_error dq config ) ) {
        $self->helper( $command => sub ( $self, @commands ) {
            return $cbqz->$command(@commands);
        } );
    }
    $self->helper( 'params' => sub ($self) {
        return { map { $_ => $self->req->param($_) } @{ $self->req->params->names } };
    } );
    $self->helper( 'req_body_json' => sub ($self) {
        my $data;
        try {
            $data = $cbqz->json->decode( $self->req->body );
        }
        catch {};
        return $data;
    } );
    $self->helper( 'cbqz' => sub { $cbqz } );
    $self->helper( 'decode_cookie' => sub ( $self, $name ) {
        my $data = {};
        try {
            $data = $cbqz->json->decode( b64_decode( $self->cookie($name) // '' ) );
        }
        catch {};
        return $data;
    } );
}

sub setup_logging ( $self, $cbqz ) {
    $self->log->level('error'); # temporarily raise log level to skip AccessLog "warn" status
    $self->plugin(
        'AccessLog',
        {
            'log' => join( '/',
                $cbqz->config->get( 'logging', 'log_dir' ),
                $cbqz->config->get( 'mojolicious', 'access_log', $self->mode ),
            )
        },
    );
    $self->log(
        MojoX::Log::Dispatch::Simple->new(
            dispatch  => $cbqz->log,
            level     => $cbqz->config->get( 'logging', 'log_level', $self->mode ),
            format_cb => sub { join( '',
                log_date(shift),
                ' [' . uc(shift) . '] ',
                join( "\n", $cbqz->dp( [ @_, '' ], colored => 0 ) ),
            ) },
        )
    );
    for my $level ( qw( debug info warn error fatal notice warning critical alert emergency emerg err crit ) ) {
        $self->helper( $level => sub {
            shift;
            $self->log->$level($_) for ( $cbqz->dp(\@_) );
            return;
        } );
    }
}

sub setup_templating ( $self, $config ) {
    push( @INC, $config->get( 'config_app', 'root_dir' ) );
    $self->plugin(
        'ToolkitRenderer',
        tt_settings( 'web', $config->get('template'), { version => $config->get('version') } ),
    );
    $self->renderer->default_handler('tt');
}

sub setup_csv ($self) {
    $self->renderer->add_handler( 'csv' => sub {
        my ( $renderer, $c, $output, $options ) = @_;

        $options->{format} = 'csv';

        if ( my $filename = $c->stash->{filename} ) {
            $c->res->headers->content_type(qq{text/csv; name="$filename"});
            $c->res->headers->content_disposition(qq{attachment; filename="$filename"});
        }

        csv( in => $c->stash->{content}, out => $output );
    } );
}

{
    my $sockets;

    sub setup_socket ( $self, $cbqz ) {
        $self->helper( 'socket' => sub ( $self, $command, $name, $params = {} ) {
            if ( $command eq 'setup' ) {
                $sockets->{$name}{callback} = $params->{cb};

                $cbqz->dq->sql(q{
                    INSERT INTO socket ( name, counter ) VALUES ( ?, 0 )
                        ON DUPLICATE KEY UPDATE name = name
                })->run($name);

                $sockets->{$name}{counter} = $cbqz->dq->sql(q{
                    SELECT counter FROM socket WHERE name = ?
                })->run($name)->value;

                $sockets->{$name}{transactions}{ sprintf( '%s', $params->{tx} ) } = $params->{tx};

                $cbqz->info("Socket $name setup");
            }
            elsif ( $command eq 'message' ) {
                $cbqz->dq->sql(q{
                    UPDATE socket SET counter = counter + 1, data = ? WHERE name = ?
                })->run( $params->{data}, $name );

                my $ppid = getppid();
                kill( 'URG', $_ ) for (
                    map { $_->[0] }
                    grep { $_->[1] == $ppid }
                    map {
                        /(\d+)\D+(\d+)/;
                        [ $1, $2 ];
                    }
                    grep { index( $_, $ppid ) != -1 }
                    `/bin/ps xa -o pid,ppid`
                );
            }
            elsif ( $command eq 'finish' ) {
                delete $sockets->{$name}{transactions}{ sprintf( '%s', $params->{tx} ) };
                $cbqz->info("Socket $name finished");
            }
            else {
                E->throw(qq{Command $command not understood});
            }
        } );

        $SIG{URG} = sub {
            for my $socket ( @{ $cbqz->dq->sql('SELECT name, counter, data FROM socket')->run->all({}) } ) {
                if (
                    $sockets->{ $socket->{name} } and
                    $sockets->{ $socket->{name} }{counter} and $socket->{counter} and
                    $sockets->{ $socket->{name} }{counter} < $socket->{counter}
                ) {
                    $sockets->{ $socket->{name} }{counter} = $socket->{counter};
                    $cbqz->debug( 'Socket ' . $socket->{name} . ' was messaged; ' . $$ . ' responding' );

                    $sockets->{ $socket->{name} }{callback}->( $_, $socket->{data} ) for (
                        values %{ $sockets->{ $socket->{name} }{transactions} }
                    );
                }
            }
        };
    }
}

1;

=head1 NAME

CBQZ::Control

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use exact;

    BEGIN {
        $ENV{CONFIGAPPENV} = $ENV{MOJO_MODE} || $ENV{PLACK_ENV} || 'development';
    }

    use Config::App;
    use Mojolicious::Commands;

    Mojolicious::Commands->start_app('CBQZ::Control');

=head1 DESCRIPTION

This class provides the C<startup> method for L<Mojolicious>.
