#!/usr/bin/env perl
use Modern::Perl '2015';
use open qw( :std :utf8 );
use Config::App;

eval join( ' ', @ARGV );
print $@ if ($@);
