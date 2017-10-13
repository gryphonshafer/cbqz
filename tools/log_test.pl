#!/usr/bin/env perl
use exact;
use open qw( :std :utf8 );
use Config::App;
use Util::CommandLine 'podhelp';
use CBQZ;

my $cbqz = CBQZ->new;

$cbqz->$_(qq{This is a message logged at the "$_" log level}) for (
    'debug',     # something logged at a pedantic level
    'info',      # complete an action within a subsystem
    'notice',    # service start, stop, restart, reload config, etc.
    'warning',   # something to investigate when time allows
    'error',     # something went wrong but probably not serious
    'critical',  # non-repeating serious error
    'alert',     # repeating serious error
    'emergency', # subsystem unresponsive or functionally broken
);

=head1 NAME

log_test.pl - Output a test of all log level messages

=head1 SYNOPSIS

    log_test.pl

=head1 DESCRIPTION

This program will output a test of all log level messages.
