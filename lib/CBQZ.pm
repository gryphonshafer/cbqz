package CBQZ;

use Moose;
use MooseX::ClassAttribute;
use exact;
use Config::App;
use DBIx::Query;
use JSON::XS;
use Mojo::UserAgent;
use Try::Tiny;
use CBQZ::Error;
use CBQZ::Util::Log;
use Data::Printer return_value => 'dump', colored => 1;

class_has config => ( isa => 'Config::App',     is => 'ro', lazy => 0, default => sub { Config::App->new } );
class_has log    => ( isa => 'Log::Dispatch',   is => 'ro', lazy => 1, default => sub { CBQZ::Util::Log->new } );
class_has ua     => ( isa => 'Mojo::UserAgent', is => 'ro', lazy => 1, default => sub { Mojo::UserAgent->new } );
class_has json   => ( isa => 'JSON::XS',        is => 'ro', lazy => 1, default => sub { return JSON::XS->new->utf8 } );

package CBQZ::_YAML {
    use exact;
    use YAML::XS ();

    sub new {
        return bless( {}, __PACKAGE__ );
    }

    sub dump {
        shift;
        return YAML::XS::Dump(@_);
    }

    sub load {
        shift;
        return YAML::XS::Load(@_);
    }

    sub dump_file {
        shift;
        return YAML::XS::DumpFile(@_);
    }

    sub load_file {
        shift;
        return YAML::XS::LoadFile(@_);
    }
}

class_has yaml => ( isa => 'CBQZ::_YAML', is => 'ro', lazy => 1, default => sub {
    return CBQZ::_YAML->new;
} );

class_has dq => ( isa => 'DBIx::Query::db', is => 'ro', lazy => 1, default => sub ($self) {
    return (
        DBIx::Query->connect(
            $self->dsn,
            @{ $self->config->get('database') }{ qw( username password settings ) },
        ) or E::Db->throw( $DBI::errstr )
    );
} );

class_has dsn => ( isa => 'Str', is => 'ro', lazy => 1, default => sub ($self) {
    my $config = $self->config->get('database');

    return 'dbi:mysql:' . join( ';',
        map { join( '=', @$_ ) }
        grep { defined $_->[1] }
        map { [ $_, $config->{$_} ] }
        qw( database host port )
    );
} );

sub params_check ( $self, @params ) {
    for (@params) {
        E->throw( $_->[0] ) if ( $_->[1]->() );
    }
}

sub able ( $self, $obj, $method ) {
    my $rv;
    try {
        $rv = $obj->can($method);
    }
    catch {
        $rv = undef;
    };

    return $rv;
}

sub clean_error ( $self, $error ) {
    return $error->message if ( ref($error) =~ /^E\b/ and $error->isa('E') );
    ( my $error_message = $error ) =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
    return $error_message;
}

sub dp ( $self, @params ) {
    return map { ( ref $_ ) ? "\n" . np($_) . "\n" : $_ } @params;
}

sub debug     ( $self, @params ) { return $self->log->debug    ( $self->dp(@params) ) }
sub info      ( $self, @params ) { return $self->log->info     ( $self->dp(@params) ) }
sub notice    ( $self, @params ) { return $self->log->notice   ( $self->dp(@params) ) }
sub warning   ( $self, @params ) { return $self->log->warning  ( $self->dp(@params) ) }
sub warn      ( $self, @params ) { return $self->log->warn     ( $self->dp(@params) ) }
sub error     ( $self, @params ) { return $self->log->error    ( $self->dp(@params) ) }
sub err       ( $self, @params ) { return $self->log->err      ( $self->dp(@params) ) }
sub critical  ( $self, @params ) { return $self->log->critical ( $self->dp(@params) ) }
sub crit      ( $self, @params ) { return $self->log->crit     ( $self->dp(@params) ) }
sub alert     ( $self, @params ) { return $self->log->alert    ( $self->dp(@params) ) }
sub emergency ( $self, @params ) { return $self->log->emergency( $self->dp(@params) ) }
sub emerg     ( $self, @params ) { return $self->log->emerg    ( $self->dp(@params) ) }

sub fork ( $self, $code ) {
    $SIG{CHLD} = 'IGNORE';
    my $pid = fork();
    if ( defined($pid) and $pid == 0 ) {
        $code->();
        exit;
    }
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

CBQZ

=head1 SYNOPSIS

    my $cbqz = CBQZ->new;

    my $config = $cbqz->config; # Config::App singleton instance
    my $log    = $cbqz->log;    # CBQZ::Util::Log singleton instance
    my $ua     = $cbqz->ua;     # Mojo::UserAgent singleton instance
    my $json   = $cbqz->json;   # JSON::XS singleton instance
    my $yaml   = $cbqz->yaml;   # YAML::XS singleton instance
    my $dq     = $cbqz->dq;     # DBIx::Query singleton instance
    my $dsn    = $cbqz->dsn;    # Database DSN string

    $cbqz->params_check(
        [ '"name" not defined in input', sub { not defined $params->{name} } ],
        [ '"name" length < 2 in input',  sub { length $params->{name} < 2 }  ],
    );

    $cbqz->able( $cbqz, 'able' ); # carefully check if $cbqz->can('able')
    my $clean_error = $cbqz->clean_error('Some error at file.pl line 42.');
    my ($colorized_error_string) = $cbqz->dp([ qw( alpha beta delta ) ]);

    $cbqz->debug('Message');
    $cbqz->info('Message');
    $cbqz->notice('Message');
    $cbqz->warn('Message');
    # ...and a whole bunch of additional log levels

=head1 DESCRIPTION

This is the primary base/parent class for most of the application. It does very
little except house some singleton objects (as properties) and provide some
simple helper methods useful in broad contexts.

=head1 PROPERTIES SINGLETON OBJECTS

The following properies contain singleton objects for easy access later in a
variety of contexts. Most of these are lazily-built.

=head2 config

Instance of L<Config::App> (very probably) loaded with CBQZ application
configuration data. For this to be true, L<Config::App> needs to be used prior
to this CBQZ module during startup. For example, in a stand-alone program:

    #!/usr/bin/env perl
    use exact;
    use Config::App;
    use CBQZ;

    say CBQZ->new->config->get('version');

=head2 log

This is a singleton instance of L<CBQZ::Util::Log>, which is a L<Log::Dispatch>
object. Typically, you wouldn't need to directly access C<log> since there are
helper methods to call for the various log levels.

=head2 ua

This is a singleton instance of L<Mojo::UserAgent>.

=head2 json

This is a singleton instance of L<JSON::XS> set with UTF8 support.

=head2 yaml

This is a singleton instance of an object that wraps and provides L<YAML::XS>
functionality. It supports: C<dump>, C<load>, C<dump_file>, and C<load_file>.
See the L<YAML::XS> documentation for more details.

    $cbqz->yaml->dump({ answer => 42 });

=head2 dq

This is a singleton instance of L<DBIx::Class> that's connected to the CBQZ
database and therefore ready to use.

    my $users = $cbqz->dq->get('user')->run->all({});

=head2 dsn

This returns a DSN string based on YAML configuration settings.

=head1 METHODS

The following are methods provided by this module.

=head2 params_check

This is a simple wrapper method that accepts any number of pairs of a string
and a subref to execute. If the subref returns false, the string is thrown as
an error.

    $cbqz->params_check(
        [ '"name" not defined in input', sub { not defined $params->{name} } ],
        [ '"name" length < 2 in input',  sub { length $params->{name} < 2 }  ],
    );

=head2 able

This is just a simple wrapper around C<can> with error trapping.

    if ( $cbqz->able( $cbqz, 'dq' ) ) {
        my $users = $cbqz->dq->get('user')->run->all({});
    }

=head2 clean_error

This method expects a string error message with context (like the "at blah line
something") and returns a "clean" string with the context removed.

    say $cbqz->clean_error('Error happened at somefile.pl line 42.');

If you pass an error object from the superclass "E" (see L<CBQZ::Error>), this
method will return the C<message> string from the object.

=head2 dp

This method wrap functionality provided by L<Data::Printer>. You can pass in any
sort of data structure, and you'll get back a "nicely" colored, probably
multi-line string ready for printing.

    say $cbqz->dp({ answer => 42 });

=head2 Logging Helper Methods

The following logging helper methods exist: C<debug>, C<info>, C<notice>,
C<warning>, C<error>, C<critical>, C<alert>, and C<emergency>. There are also
the following additional aliases: C<warn>, C<err>, C<crit>, and C<emerg>.

These all accept any number of simple or complex data and will log the input
at the associated log level.

    $cbqz->error('Something bad happened');
    $cbqz->warn({ answer => 42 });
