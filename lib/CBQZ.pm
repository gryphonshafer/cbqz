package CBQZ;

use Moose;
use MooseX::ClassAttribute;
use Config::App;
use DBIx::Query;
use JSON::XS;
use Mojo::UserAgent;
use Try::Tiny;
use CBQZ::Error;
use CBQZ::Util::Log;

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

sub params_check {
    my $self = shift;

    for (@_) {
        E->throw( $_->[0] ) if ( $_->[1]->() );
    }
}

sub able {
    my ( $self, $obj, $method ) = @_;

    my $rv;
    try {
        $rv = $obj->can($method);
    }
    catch {
        $rv = undef;
    };

    return $rv;
}

sub clean_error {
    my ( $self, $error_with_context ) = @_;
    ( my $error_without_context = $error_with_context ) =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
    return $error_without_context;
}

sub debug     { shift->log->debug(@_) }
sub info      { shift->log->info(@_) }
sub notice    { shift->log->notice(@_) }
sub warning   { shift->log->warning(@_) }
sub warn      { shift->log->warn(@_) }
sub error     { shift->log->error(@_) }
sub err       { shift->log->err(@_) }
sub critical  { shift->log->critical(@_) }
sub crit      { shift->log->crit(@_) }
sub alert     { shift->log->alert(@_) }
sub emergency { shift->log->emergency(@_) }
sub emerg     { shift->log->emerg(@_) }

__PACKAGE__->meta->make_immutable;

1;
