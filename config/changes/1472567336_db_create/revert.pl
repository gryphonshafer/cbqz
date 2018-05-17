#!/usr/bin/env perl
use exact;
use Config::App;
use CBQZ;

# dest.prereq: config/changes/1472568489_create_tables

my $cbqz     = CBQZ->new;
my $database = $cbqz->config->get( qw( database database ) );

$cbqz->config->put( qw( database database ) => undef );
$cbqz->dq->sql('DROP DATABASE $database')->run;
