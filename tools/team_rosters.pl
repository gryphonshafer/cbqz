#!/usr/bin/env perl
use exact;
use Util::CommandLine qw( options pod2usage );
use Text::CSV_XS 'csv';
use IO::All 'io';

my $settings = options( qw( quizzers|q=s schedule|s=s ) );
pod2usage unless ( $settings->{quizzers} and $settings->{schedule} );

my %teams;
push(
    @{ $teams{ $_->{Team} } },
    {
        Bib     => $_->{Bib},
        Quizzer => $_->{Quizzer},
    },
) for ( @{ csv( in => $settings->{quizzers}, headers => 'auto' ) } );

%teams = map {
    $_ => join(
        "\n",
        map { $_->{Bib} . '. ' . $_->{Quizzer} } sort { $a->{Bib} cmp $b->{Bib} } @{ $teams{$_} },
    ) . "\n"
} keys %teams;

for ( @{ io( $settings->{schedule} ) } ) {
    say $_;
    say $teams{$_} if ( $teams{$_} );
}

=head1 NAME

team_rosters.pl - Generate quiz meet team rosters schedule sheet

=head1 SYNOPSIS

    team_rosters.pl OPTIONS
        -q|quizzers CSV_FILE
        -s|schedule TEXT_FILE
        -h|help
        -m|man

=head1 DESCRIPTION

This program will generate a quiz meet team rosters schedule sheet from a
quizzer roster CSV and team-name schedule list.

The quizzers CSV file is expected to contain the columns: Team, and Bib, and
Quizzer. It should also include a header using the proper column names. The
schedule text file is expected to simply contain blocks of team names
clustered by quiz; for example:

    TEAM NAME A
    TEAM NAME B
    TEAM NAME C

    TEAM NAME D
    TEAM NAME A
    TEAM NAME F
