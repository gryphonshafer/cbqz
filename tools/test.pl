#!/usr/bin/env perl
use exact;
use open qw( :std :utf8 );
use Config::App;

eval join( ' ', @ARGV );
print $@ if ($@);
