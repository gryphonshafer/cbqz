#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Try::Tiny;
use CBQZ::Model::Question;
use CBQZ::Model::QuestionSet;
use CBQZ::Model::MaterialSet;

my $settings = options( qw( user|u=s questions|q=s materials|m=s ) );
pod2usage unless ( $settings->{user} and $settings->{questions} and $settings->{materials} );

my ( $question_set, $material_set );

try {
    $question_set = CBQZ::Model::QuestionSet->new->load(
        {
            'me.name'       => $settings->{questions},
            'user.username' => $settings->{user},
        },
        {
            join => 'user',
        }
    );
}
catch {
    die "Unable to load question set\n";
};

try {
    $material_set = CBQZ::Model::MaterialSet->new->load( { 'name' => $settings->{materials} } );
}
catch {
    die "Unable to load material set\n";
};

$| = 1;
for my $question ( CBQZ::Model::Question->new->model( $question_set->obj->questions->all ) ) {
    $question->calculate_score($material_set);
    print '.';
}
print "\n";

=head1 NAME

score_questions.pl - Calculate and save question score for a question set.

=head1 SYNOPSIS

    score_questions.pl OPTIONS
        -u|user       USERNAME
        -q|questions  QUESTION_SET_NAME
        -m|materials  MATERIAL_SET_NAME
        -h|help
        -m|man

=head1 DESCRIPTION

This program will calculate and save question score for a question set.
