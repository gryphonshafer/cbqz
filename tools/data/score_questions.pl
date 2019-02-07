#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Try::Tiny;
use Progress::Any;
use Progress::Any::Output;
use CBQZ::Model::Question;
use CBQZ::Model::QuestionSet;
use CBQZ::Model::MaterialSet;

my $settings = options( qw( all|a id|i=s user|u=s questions|q=s set|s=s ) );
pod2usage unless (
    (
        $settings->{all} or $settings->{id} or
        ( $settings->{user} and $settings->{questions} )
    ) and $settings->{set}
);

my $material_set;
try {
    $material_set = CBQZ::Model::MaterialSet->new->load( { 'name' => $settings->{set} } );
}
catch {
    die "Unable to load material set\n";
};

my $question_set;
unless ( $settings->{all} or $settings->{id} ) {
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
}

my @questions = ( $settings->{id} )
    ? CBQZ::Model::Question->new->load( $settings->{id} )
    : CBQZ::Model::Question->new->model(
        ( $settings->{all} )
            ? CBQZ::Model::Question->new->rs->search->all
            : $question_set->obj->questions->all
    );

my $progress = Progress::Any->get_indicator( task => 'work', target => scalar(@questions) );
Progress::Any::Output->set( { task => 'work' }, 'TermProgressBarColor' );

for my $question (@questions) {
    $question->calculate_score($material_set);
    $progress->update;
}
$progress->finish;

=head1 NAME

score_questions.pl - Calculate and save question score for a question set.

=head1 SYNOPSIS

    score_questions.pl OPTIONS
        -u|user       USERNAME
        -q|questions  QUESTION_SET_NAME
        -a|all
        -i|id         QUESTION_DATABASE_PK_ID
        -s|set        MATERIAL_SET_NAME
        -h|help
        -m|man

=head1 DESCRIPTION

This program will calculate and save question score for a question set. It
requires either a question set name and username or the "all" flag to be set,
indicating all questions in the database. It also needs a material set named.

    ./score_questions.pl -u username -q 'Questions' -s 'Materials'
    ./score_questions.pl -a -s 'Materials'
    ./score_questions.pl -i 42 -s 'Materials'
