package CBQZ;

use Moose;
use MooseX::ClassAttribute;
use Config::App;
use Try::Tiny;

use CBQZ::Error;
use CBQZ::Util::Log;

class_has log => ( isa => 'Log::Dispatch', is => 'ro', lazy => 1, default => sub {
    return CBQZ::Util::Log->new;
} );

class_has conf => ( isa => 'Config::App', is => 'ro', default => sub { Config::App->new } );

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
