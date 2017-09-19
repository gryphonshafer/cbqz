package CBQZ::Control;

use exact;
use Mojo::Base 'Mojolicious';
use Mojo::Loader 'load_class';
use MojoX::Log::Dispatch::Simple;
use Try::Tiny;
use CBQZ;
use CBQZ::Model::User;
use CBQZ::Util::Format 'log_date';

sub startup {
    my ( $self, $app ) = @_;

    my $cbqz   = CBQZ->new;
    my $config = $cbqz->config;

    $self->static->paths->[0] =~ s|/public$|/static|;
    $self->sessions->cookie_name( $config->get( 'mojolicious', 'cookie_name' ) );
    $self->secrets( $config->get( 'mojolicious', 'secrets' ) );
    $self->config( $config->get( 'mojolicious', 'config' ) );
    $self->sessions->default_expiration(0);

    # setup general helpers
    for my $command ( qw( clean_error dq config ) ) {
        $self->helper( $command => sub {
            my $self = shift;
            return $cbqz->$command(@_);
        } );
    }
    $self->helper( 'params' => sub {
        my ($self) = @_;
        return { map { $_ => $self->req->param($_) } @{ $self->req->params->names } };
    } );
    $self->helper( 'req_body_json' => sub {
        my ($self) = @_;
        my $data;
        try {
            $data = $cbqz->json->decode( $self->req->body );
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
            format_cb => sub { log_date(shift) . ' [' . uc(shift) . '] ' . join( "\n", @_, '' ) },
        )->helpers($self)
    );

    # template processing
    $self->plugin(
        'ToolkitRenderer',
        {
            config => {
                INCLUDE_PATH => $config->get( 'template', 'include_path' ),
                COMPILE_EXT  => $config->get( 'template', 'compile_ext' ),
                COMPILE_DIR  => $config->get( 'template', 'compile_dir', $self->mode ),
                WRAPPER      => $config->get( 'template', 'wrapper' ),
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

    $self->plugin('PODRenderer') if ( $self->mode eq 'development' );

    # JSON rendering
    $self->renderer->add_handler( 'json' => sub { ${ $_[2] } = eval { $cbqz->json->encode( $_[3]{json} ) } } );

    # set default rendering handler
    $self->renderer->default_handler('tt');

    # pre-load controllers
    load_class( 'CBQZ::Control::' . $_ ) for qw( Main Editor );

    # before dispatch tasks
    $self->hook( 'before_dispatch' => sub {
        my ($self) = @_;

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

            $self->stash( 'user' => $user ) if ($user);
        }
    });

    # routes setup section
    my $anyone = $self->routes;

    $anyone->any('/')->to('main#index');
    $anyone->any( '/' . $_ )->to( controller => 'main', action => $_ ) for ( qw( login logout create_user ) );
    $anyone->any('/create-user')->to( controller => 'main', action => 'create_user' );

    my $authorized_user = $anyone->under( sub {
        my ($self) = @_;
        return 1 if ( $self->stash('user') and $self->stash('user')->roles > 0 );

        $self->info('Login required but not yet met');
        return $self->redirect_to('/');
    } );

    $authorized_user->any('/:controller')->to( action => 'index' );
    $authorized_user->any('/:controller/:action');

    return;
}

1;
