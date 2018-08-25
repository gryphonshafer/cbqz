#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use CBQZ::Model::Meet;

my $settings = options( qw( rooms|r=i teams|t=i quizzes|q=i ) );
pod2usage unless ( $settings->{rooms} and $settings->{teams} and $settings->{quizzes} );

# build team objects
my $team_name      = 'A';
$settings->{teams} = [ map { $team_name++ } 1 .. $settings->{teams} ];

my $meet = CBQZ::Model::Meet->build_draw($settings);

my $set_count;
for my $set (@$meet) {
    printf '%3d: ', ++$set_count;
    printf '%12s', $_ for (
        map {
            join( ' ', map { sprintf '%-2s', $_->{name} } @$_ )
        } @$set
    );
    print "\n";
}

=head1 NAME

quiz_schedule.pl - Generate a quiz meet schedule based on simple inputs

=head1 SYNOPSIS

    quiz_schedule.pl OPTIONS
        -r|rooms N
        -t|teams N
        -q|quizzes N
        -h|help
        -m|man

=head1 DESCRIPTION

This program will generate a quiz meet schedule based on simple inputs.
