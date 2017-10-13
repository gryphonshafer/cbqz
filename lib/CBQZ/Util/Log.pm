package CBQZ::Util::Log;

use exact;
use Config::App;
use File::Path 'make_path';
use Log::Dispatch;
use Term::ANSIColor ();
use CBQZ::Util::Format 'log_date';

sub new {
    my $config = Config::App->new;

    my $log_level_set = $config->get( 'logging', 'log_level' );
    my $log_level     = _lowest_level( map { $log_level_set->{$_} } keys %$log_level_set );

    my $log_dir = join( '/',
        $config->get( qw( config_app root_dir ) ),
        $config->get( qw( logging log_dir ) ),
    );
    make_path($log_dir) unless ( -d $log_dir );

    my $log_obj = Log::Dispatch->new(
        outputs => [
            [
                'Screen',
                name      => 'stdout',
                min_level => _highest_level( $log_level, 'debug' ),
                max_level => 'notice',
                newline   => 1,
                callbacks => [ \&_log_cb_label, \&_log_cb_time, \&_log_cb_color ],
                stderr    => 0,
            ],
            [
                'Screen',
                name      => 'stderr',
                min_level => _highest_level( $log_level, 'warning' ),
                newline   => 1,
                callbacks => [ \&_log_cb_label, \&_log_cb_time, \&_log_cb_color ],
                stderr    => 1,
            ],
            [
                'File',
                name      => 'log_file',
                min_level => _highest_level( $log_level, 'debug' ),
                newline   => 1,
                callbacks => [ \&_log_cb_label, \&_log_cb_time, \&_log_cb_color ],
                mode      => 'append',
                autoflush => 1,
                filename  => join( '/',
                    $config->get( qw( config_app root_dir ) ),
                    $config->get( qw( logging log_dir ) ),
                    $config->get( qw( logging log_file ) ),
                ),
            ],
            [
                'Email::Mailer',
                name      => 'email',
                min_level => _highest_level( $log_level, 'alert' ),
                to        => $config->get( 'logging', 'alert_email' ),
                subject   => 'CBQZ Alert Log Message',
            ],
        ],
    );

    my $filter = $config->get( 'logging', 'filter' );
    $filter = ( ref $filter ) ? $filter : ($filter) ? [$filter] : [];
    $filter = [ map { $_->{name} } $log_obj->outputs ] if ( grep { lc($_) eq 'all' } @$filter );

    $log_obj->remove($_) for (@$filter);
    return $log_obj;
}

{
    my $log_levels = {
        debug => 1,
        info  => 2,
        warn  => 3,
        error => 4,
        fatal => 5,

        notice    => 2,
        warning   => 3,
        critical  => 4,
        alert     => 5,
        emergency => 5,
        emerg     => 5,

        err  => 4,
        crit => 4,
    };

    sub _lowest_level {
        return (
            map { $_->[1] }
            sort { $a->[0] <=> $b->[0] }
            map { [ $log_levels->{$_}, $_ ] }
            @_
        )[0];
    }

    sub _highest_level {
        return (
            map { $_->[1] }
            sort { $b->[0] <=> $a->[0] }
            map { [ $log_levels->{$_}, $_ ] }
            @_
        )[0];
    }
}

sub _log_cb_time {
    my %msg = @_;
    return log_date() . ' ' . $msg{message};
}

sub _log_cb_label {
    my %msg = @_;
    return '[' . uc( $msg{level} ) . '] ' . $msg{message};
}

{
    my %color = (
        reset  => Term::ANSIColor::color('reset'),
        bold   => Term::ANSIColor::color('bold'),

        debug     => 'cyan',
        info      => 'white',
        notice    => 'bright_white',
        warning   => 'yellow',
        error     => 'bright_red',
        critical  => [ qw( underline bright_red ) ],
        alert     => [ qw( underline bright_yellow) ],
        emergency => [ qw( underline bright_yellow on_blue ) ],
    );

    for ( qw( debug info notice warning error critical alert emergency ) ) {
        next unless ( $color{$_} );
        $color{$_} = join ( '', map {
            $color{$_} = Term::ANSIColor::color($_) unless ( $color{$_} );
            $color{$_};
        } ( ( ref $color{$_} ) ? @{ $color{$_} } : $color{$_} ) );
    }

    sub _log_cb_color {
        my %msg = @_;
        return ( $color{ $msg{level} } )
            ? $color{ $msg{level} } . $msg{message} . $color{reset}
            : $msg{message};
    }
}

1;

=head1 NAME

CBQZ::Util::Log

=head1 SYNOPSIS

    use CBQZ::Util::Log;

    my $log      = CBQZ::Util::Log->new;
    my $pedantic = CBQZ::Util::Log->new(0);

    $log->info(      'complete an action within a subsystem'             );
    $log->notice(    'service start, stop, restart, reload config, etc.' );
    $log->warning(   'something to investigate when time allows'         );
    $log->error(     'something went wrong but probably not serious'     );
    $log->critical(  'non-repeating serious error'                       );
    $log->alert(     'repeating serious error'                           );
    $log->emergency( 'subsystem unresponsive or functionally broken'     );

    $pedantic->debug('something logged at a pedantic level (normally disabled)');

=head1 DESCRIPTION

This module provides a single method, the C<new()> constructor, that when called
returns a L<Log::Dispatch> object setup as is considered "good" by this module.
It will have appropriate settings for logging along the 8 log levels defined by
L<Log::Dispatch>. It will also do some nifty things like adding ANSI color to
messages in text-based logs.

=head2 new

Typically, you'll just want to call C<new()> and use the log object returned
by calling a log level on it and providing content.

    my $log = CBQZ::Util::Log->new;
    $log->warning('a warning about something');

In this context, C<$log> will log using all preset output objects except the
"debug" object, which due to its settings means it won't log "debug" messages.

Alternatively, you can specify to the C<new()> constructor a list of objects
to remove, or "0" that means to include all objects.

    my $log = CBQZ::Util::Log->new(0);
    $log->debug('this debug message will now get logged');

    my $log_sans_debug_and_stdout = CBQZ::Util::Log->new( qw( debug stdout ) );

=head2 Log Level, Meanings, and Outputs

The following are the log levels and their meanings:

    debug     = everything at a pedantic level (normally disabled)
    info      = completed actions within a subsystem
    notice    = service start, stop, restart, reload config, etc.
    warning   = something to investigate when time allows
    error     = something went wrong but probably not serious
    critical  = non-repeating serious error
    alert     = repeating serious error
    emergency = subsystem unresponsive or functionally broken

The following are the log levels and their outputs:

    debug     = STDOUT/Screen
    info      = STDOUT/Screen, DBI
    notice    = STDOUT/Screen
    warning   = STDERR/Screen
    error     = STDERR/Screen, Email::EmailSender (on-call person)
    critical  = STDERR/Screen, Email::EmailSender (on-call person)
    alert     = STDERR/Screen, Email::EmailSender (universe), Twilio (on-call person)
    emergency = STDERR/Screen, Email::EmailSender (universe), Twilio (universe)

=head2 Log Objects

The following are the log objects and their log level ranges:

    debug  = debug
    stdout = info .. notice
    stderr = warning .. emergency

=head1 INHERITANCE AND DEPENDENCIES

This module inherits from nothing.

This module has the following dependencies:

=over 1

=item * L<Config::App>

=item * L<Log::Dispatch>

=item * L<Term::ANSIColor>

=item * L<CBQZ::Util::Format>

=back
