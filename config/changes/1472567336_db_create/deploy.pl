#!/usr/bin/env perl
use exact;
use Config::App;
use CBQZ;

my $cbqz     = CBQZ->new;
my $database = $cbqz->config->get( qw( database database ) );

$cbqz->config->put( qw( database database ) => undef );
$cbqz->dq->sql(qq{CREATE DATABASE $database CHARACTER SET utf8 COLLATE utf8_general_ci})->run;
