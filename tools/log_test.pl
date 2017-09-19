#!/usr/bin/env perl
use exact;
use open qw( :std :utf8 );
use Config::App;
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
