#!/usr/bin/env perl
use exact;
use Util::CommandLine qw( options pod2usage );
use Text::CSV_XS 'csv';
use IO::All 'io';

my $settings = options('roster|r=s');
pod2usage unless ( $settings->{roster} );

my %teams = grep { defined } map {
    my $r = $_;
    ( $r->{TEAM} )
        ? ( $r->{TEAM} => [ grep { /\d+\.\s*\w/ } map { $r->{ 'Bib ' . $_ } } ( 1 .. 5 ) ] )
        : undef;
} ( @{ csv( in => $settings->{roster}, headers => 'auto' ) } );

say join( "\n", $_, sort @{ $teams{$_} } ), "\n" for ( sort keys %teams );

=head1 NAME

list_from_roster.pl - Generate team/quizzers list from roster

=head1 SYNOPSIS

    list_from_roster.pl OPTIONS
        -r|roster CSV_FILE
        -h|help
        -m|man

=head1 DESCRIPTION

This program will generate a team and quizzers list (suitable for copy-and-paste
into the CBQZ web UI) from a CSV export of the meet roster data typically
distributed by the meet director.

The CSV is expected to have a header row. The columns necessary are:
"TEAM" for team name and "Bib N" where "N" is an integer.
