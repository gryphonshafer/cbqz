#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine 'podhelp';
use CBQZ;
use CBQZ::Util::File 'slurp';

my $cbqz = CBQZ->new;

$cbqz->dq->sql('UPDATE program SET result_operation = ?')->run(
    slurp(
        $cbqz->config->get( 'config_app', 'root_dir' ) . '/static/js/pages/result_operation.js'
    )
);

=head1 NAME

set_result_operation.pl - Set result operation to file source

=head1 SYNOPSIS

    set_result_operation.pl

=head1 DESCRIPTION

This program will read the result operation data from file source and save it as
active for all programs (in the database).
