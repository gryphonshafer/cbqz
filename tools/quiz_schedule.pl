#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Try::Tiny;
use CBQZ::Model::Meet;

my $settings = options( qw( rooms|r=i teams|t=i quizzes|q=i norandom|n stats|s ) );
pod2usage unless ( $settings->{rooms} and $settings->{teams} and $settings->{quizzes} );

# build team objects
my $team_name      = 'A';
$settings->{teams} = [ map { $team_name++ } 1 .. $settings->{teams} ];

my ( $meet, $stats );
try {
    ( $meet, $stats ) = CBQZ::Model::Meet->build_draw($settings);
}
catch {
    die CBQZ::Model::Meet->clean_error($_) . "\n";
};

say 'Quiz meet schedule:';
printf '         ' . ( '%12s' x $settings->{rooms} ) . "\n", map { 'Room ' . $_ } ( 1 .. $settings->{rooms} );

my $set_count;
for my $set (@$meet) {
    printf '  Set %3d: ', ++$set_count;
    printf '%12s', $_ for (
        map {
            join( ' ', map { sprintf '%-2s', $_ } @$_ )
        } @$set
    );
    print "\n";
}

if ( $settings->{stats} ) {
    print "\n";
    for my $team (@$stats) {
        say 'Team: ', $team->{name}, ' (', $team->{quizzes}, ' quizzes)';
        say '  Quizzes by room: ', join( ', ',
            map { $_ . ' (' . $team->{rooms}{$_} . 'x)' } sort { $a <=> $b } keys %{ $team->{rooms} }
        );
        say '  Opponents faced: ', join( ', ',
            map { $_ . ' (' . $team->{teams}{$_} . 'x)' } sort { $a cmp $b } keys %{ $team->{teams} }
        );
        print "\n";
    }
}

=head1 NAME

quiz_schedule.pl - Generate a quiz meet schedule based on simple inputs

=head1 SYNOPSIS

    quiz_schedule.pl OPTIONS
        -r|rooms N
        -t|teams N
        -q|quizzes N
        -n|norandom
        -s|stats
        -h|help
        -m|man

=head1 DESCRIPTION

This program will generate a quiz meet schedule based on simple inputs.
