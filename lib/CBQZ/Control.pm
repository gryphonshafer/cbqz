package CBQZ::Control;

use Mojo::Base 'Mojolicious';
use exact;
use Mojo::Loader 'load_class';
use Mojo::Util 'b64_decode';
use MojoX::Log::Dispatch::Simple;
use Try::Tiny;
use CBQZ;
use CBQZ::Model::User;
use CBQZ::Util::Format 'log_date';

sub startup ( $self, $app = undef ) {
    my $cbqz   = CBQZ->new;
    my $config = $cbqz->config;

    # base URL handling
    $self->plugin('RequestBase');

    $self->static->paths->[0] =~ s|/public$|/static|;
    $self->sessions->cookie_name( $config->get( 'mojolicious', 'session_cookie_name' ) );
    $self->secrets( $config->get( 'mojolicious', 'secrets' ) );
    $self->config( $config->get( 'mojolicious', 'config' ) );
    $self->sessions->default_expiration(0);

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

    # logging
    $self->log->level('error'); # temporarily raise log level to skip AccessLog "warn" status
    $self->plugin(
        'AccessLog',
        {
            'log' => join( '/',
                $config->get( 'logging', 'log_dir' ),
                $config->get( 'mojolicious', 'access_log', $self->mode ),
            )
        },
    );
    $self->log(
        MojoX::Log::Dispatch::Simple->new(
            dispatch  => $cbqz->log,
            level     => $config->get( 'logging', 'log_level', $self->mode ),
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

    # template processing
    my $tt_conf = $config->get('template');
    push( @INC, $config->get( 'config_app', 'root_dir' ) );
    $self->plugin(
        'ToolkitRenderer',
        {
            config => {
                INCLUDE_PATH => $tt_conf->{'include_path'},
                COMPILE_EXT  => $tt_conf->{'compile_ext'},
                COMPILE_DIR  => $tt_conf->{'compile_dir'},
                WRAPPER      => $tt_conf->{'wrapper'},
                CONSTANTS    => {
                    version => $config->get('version'),
                },
                FILTERS => {
                    ucfirst => sub { return ucfirst shift },
                    round   => sub { return int( $_[0] + 0.5 ) },
                },
                ENCODING => 'utf8',
            },
            context => sub {
                my ($context) = @_;

                $context->define_vmethod( 'scalar', 'lower',   sub { return lc( $_[0] ) } );
                $context->define_vmethod( 'scalar', 'upper',   sub { return uc( $_[0] ) } );
                $context->define_vmethod( 'scalar', 'ucfirst', sub { return ucfirst( lc( $_[0] ) ) } );

                $context->define_vmethod( $_, 'ref', sub { return ref( $_[0] ) } )
                    for ( qw( scalar list hash ) );
            },
        },
    );

    # JSON rendering
    $self->renderer->add_handler( 'json' => sub { ${ $_[2] } = eval { $cbqz->json->encode( $_[3]{json} ) } } );

    # set default rendering handler
    $self->renderer->default_handler('tt');

    # pre-load controllers
    load_class( 'CBQZ::Control::' . $_ ) for qw( Main Editor Quizroom );

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
            $self->stash('user')->roles_count > 0 and
            $self->stash('user')->programs_count > 0
        );

        $self->info('Login required but not yet met');
        $self->redirect_to('/');
        return 0;
    } );

    $authorized_user->any('/:controller')->to( action => 'index' );
    $authorized_user->any('/:controller/:action');

    return;
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
