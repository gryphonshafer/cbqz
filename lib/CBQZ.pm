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

package __PACKAGE__::_YAML {
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

class_has dq => ( isa => 'DBIx::Query::db', is => 'ro', lazy => 1, default => sub {
    return (
        DBIx::Query->connect(
            join( '', @{ Config::App->new->get('database') }{ qw( dsn dbname ) } ),
            @{ Config::App->new->get('database') }{ qw( username password settings ) },
        ) or E::Db->throw( $DBI::errstr )
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

sub clean_error ( $self, $error_with_context ) {
    ( my $error_without_context = $error_with_context ) =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
    return $error_without_context;
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

__PACKAGE__->meta->make_immutable;

1;
