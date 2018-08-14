package CBQZ::Control;

use Mojo::Base 'Mojolicious';
use exact;
use Mojo::Loader 'load_class';
use Mojo::Util 'b64_decode';
use MojoX::Log::Dispatch::Simple;
use Try::Tiny;
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
    $self->sessions->cookie_name( $config->get( 'mojolicious', 'session_cookie_name' ) );
    $self->secrets( $config->get( 'mojolicious', 'secrets' ) );
    $self->config( $config->get( 'mojolicious', 'config' ) );
    $self->sessions->default_expiration(0);

    $self->setup_general_helpers($cbqz);
    $self->setup_logging($cbqz);
    $self->setup_templating($config);
    $self->setup_csv;

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
            $last_request_time < time - $config->get( qw( mojolicious session_duration ) )
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
    $anyone->any( '/' . $_ )->to( controller => 'main', action => $_ ) for ( qw( login logout create_user ) );
    $anyone->any('/create-user')->to( controller => 'main', action => 'create_user' );

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
    $admin_user->any('/admin/:action')->to( controller => 'admin' );

    $authorized_user->any('/:controller')->to( action => 'index' );
    $authorized_user->any('/:controller/:action');

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
        };
        return $data;
    } );
    $self->helper( 'cbqz' => sub { $cbqz } );
    $self->helper( 'decode_cookie' => sub ( $self, $name ) {
        my $data = {};
        try {
            $data = $cbqz->json->decode( b64_decode( $self->cookie($name) // '' ) );
        };
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
            format_cb => sub { log_date(shift) . ' [' . uc(shift) . '] ' . join( "\n", $cbqz->dp( @_, '' ) ) },
        )
    );
    for my $level ( qw( debug info warn error fatal notice warning critical alert emergency emerg err crit ) ) {
        $self->helper( $level => sub {
            shift;
            $self->log->$level($_) for ( $cbqz->dp(@_) );
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
